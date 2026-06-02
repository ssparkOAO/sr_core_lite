import struct
from pathlib import Path

import numpy as np


TENSOR_TYPE_TO_DTYPE = {
    0: np.float32,
    2: np.int32,
    3: np.uint8,
    4: np.int64,
    6: np.bool_,
    7: np.int16,
    9: np.int8,
    10: np.float16,
}

TENSOR_TYPE_TO_NAME = {
    0: "FLOAT32",
    2: "INT32",
    3: "UINT8",
    4: "INT64",
    6: "BOOL",
    7: "INT16",
    9: "INT8",
    10: "FLOAT16",
}

BUILTIN_OPCODE_NAMES = {
    0: "ADD",
    3: "CONV_2D",
    5: "DEPTH_TO_SPACE",
    6: "DEQUANTIZE",
    9: "FULLY_CONNECTED",
    18: "MUL",
    19: "RELU",
    22: "RESHAPE",
    25: "SOFTMAX",
    57: "MINIMUM",
    114: "QUANTIZE",
}


class FlatBufferReader:
    def __init__(self, data):
        self.data = data

    def u8(self, off):
        return self.data[off]

    def i8(self, off):
        return struct.unpack_from("<b", self.data, off)[0]

    def u16(self, off):
        return struct.unpack_from("<H", self.data, off)[0]

    def i32(self, off):
        return struct.unpack_from("<i", self.data, off)[0]

    def u32(self, off):
        return struct.unpack_from("<I", self.data, off)[0]

    def f32(self, off):
        return struct.unpack_from("<f", self.data, off)[0]

    def root_table(self):
        return self.u32(0)

    def field_pos(self, table, field_id):
        vtable = table - self.i32(table)
        vtable_size = self.u16(vtable)
        entry = 4 + field_id * 2
        if entry + 2 > vtable_size:
            return None
        rel = self.u16(vtable + entry)
        if rel == 0:
            return None
        return table + rel

    def table_field(self, table, field_id):
        pos = self.field_pos(table, field_id)
        if pos is None:
            return None
        return pos + self.u32(pos)

    def string_field(self, table, field_id):
        pos = self.field_pos(table, field_id)
        if pos is None:
            return ""
        start = pos + self.u32(pos)
        length = self.u32(start)
        raw = self.data[start + 4 : start + 4 + length]
        return raw.decode("utf-8", errors="replace")

    def scalar_field(self, table, field_id, kind, default=0):
        pos = self.field_pos(table, field_id)
        if pos is None:
            return default
        if kind == "u8":
            return self.u8(pos)
        if kind == "i8":
            return self.i8(pos)
        if kind == "u16":
            return self.u16(pos)
        if kind == "u32":
            return self.u32(pos)
        if kind == "i32":
            return self.i32(pos)
        if kind == "f32":
            return self.f32(pos)
        raise ValueError(f"Unsupported scalar kind: {kind}")

    def vector_start_from_pos(self, pos):
        start = pos + self.u32(pos)
        length = self.u32(start)
        return start + 4, length

    def vector_table_field(self, table, field_id):
        pos = self.field_pos(table, field_id)
        if pos is None:
            return []
        data_start, length = self.vector_start_from_pos(pos)
        out = []
        for idx in range(length):
            elem_pos = data_start + idx * 4
            out.append(elem_pos + self.u32(elem_pos))
        return out

    def vector_int32_field(self, table, field_id):
        pos = self.field_pos(table, field_id)
        if pos is None:
            return []
        data_start, length = self.vector_start_from_pos(pos)
        return [self.i32(data_start + idx * 4) for idx in range(length)]

    def vector_uint8_field(self, table, field_id):
        pos = self.field_pos(table, field_id)
        if pos is None:
            return bytes()
        data_start, length = self.vector_start_from_pos(pos)
        return bytes(self.data[data_start : data_start + length])

    def vector_float32_field(self, table, field_id):
        pos = self.field_pos(table, field_id)
        if pos is None:
            return []
        data_start, length = self.vector_start_from_pos(pos)
        return [self.f32(data_start + idx * 4) for idx in range(length)]


class TFLiteModel:
    def __init__(self, path):
        self.path = Path(path)
        self.reader = FlatBufferReader(self.path.read_bytes())
        self.model = self.reader.root_table()
        self.operator_codes = self._parse_operator_codes()
        self.subgraph = self.reader.vector_table_field(self.model, 2)[0]
        self.buffers = self.reader.vector_table_field(self.model, 4)
        self.tensors = self._parse_tensors()
        self.operators = self._parse_operators()
        self.inputs = self.reader.vector_int32_field(self.subgraph, 1)
        self.outputs = self.reader.vector_int32_field(self.subgraph, 2)

    def _parse_operator_codes(self):
        out = []
        for table in self.reader.vector_table_field(self.model, 1):
            deprecated_code = self.reader.scalar_field(table, 0, "i8", 0)
            builtin_code = self.reader.scalar_field(table, 3, "i32", deprecated_code)
            out.append(
                {
                    "builtin_code": int(builtin_code),
                    "name": BUILTIN_OPCODE_NAMES.get(int(builtin_code), f"OP_{builtin_code}"),
                }
            )
        return out

    def _parse_quantization(self, q_table):
        if q_table is None:
            return {
                "scales": [],
                "zero_points": [],
                "quantized_dimension": 0,
            }
        return {
            "scales": self.reader.vector_float32_field(q_table, 2),
            "zero_points": self.reader.vector_int32_field(q_table, 3),
            "quantized_dimension": int(self.reader.scalar_field(q_table, 5, "i32", 0)),
        }

    def _parse_tensors(self):
        out = []
        for idx, table in enumerate(self.reader.vector_table_field(self.subgraph, 0)):
            shape = self.reader.vector_int32_field(table, 0)
            tensor_type = int(self.reader.scalar_field(table, 1, "i8", 0))
            buffer_idx = int(self.reader.scalar_field(table, 2, "u32", 0))
            name = self.reader.string_field(table, 3)
            quant = self._parse_quantization(self.reader.table_field(table, 4))
            shape_signature = self.reader.vector_int32_field(table, 7)
            out.append(
                {
                    "index": idx,
                    "name": name,
                    "shape": shape,
                    "shape_signature": shape_signature,
                    "type": tensor_type,
                    "type_name": TENSOR_TYPE_TO_NAME.get(tensor_type, str(tensor_type)),
                    "buffer": buffer_idx,
                    "quantization": quant,
                }
            )
        return out

    def _parse_operators(self):
        out = []
        for idx, table in enumerate(self.reader.vector_table_field(self.subgraph, 3)):
            opcode_index = int(self.reader.scalar_field(table, 0, "u32", 0))
            op_code = self.operator_codes[opcode_index]["builtin_code"]
            out.append(
                {
                    "index": idx,
                    "opcode_index": opcode_index,
                    "builtin_code": op_code,
                    "op_name": BUILTIN_OPCODE_NAMES.get(op_code, f"OP_{op_code}"),
                    "inputs": self.reader.vector_int32_field(table, 1),
                    "outputs": self.reader.vector_int32_field(table, 2),
                }
            )
        return out

    def tensor_data(self, tensor_idx):
        tensor = self.tensors[tensor_idx]
        buffer_idx = tensor["buffer"]
        if buffer_idx < 0 or buffer_idx >= len(self.buffers):
            return None
        raw = self.reader.vector_uint8_field(self.buffers[buffer_idx], 0)
        if not raw:
            return None
        dtype = TENSOR_TYPE_TO_DTYPE.get(tensor["type"])
        if dtype is None:
            raise ValueError(f"Unsupported tensor type: {tensor['type_name']}")
        arr = np.frombuffer(raw, dtype=dtype)
        shape = tensor["shape"]
        if shape and int(np.prod(shape)) == arr.size:
            arr = arr.reshape(shape)
        return arr.copy()

    def conv_operators(self):
        return [op for op in self.operators if op["op_name"] == "CONV_2D"]

