# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "IN_COUNT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OUT_BYTE_COUNT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OUT_WORD_COUNT" -parent ${Page_0}


}

proc update_PARAM_VALUE.IN_COUNT { PARAM_VALUE.IN_COUNT } {
	# Procedure called to update IN_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IN_COUNT { PARAM_VALUE.IN_COUNT } {
	# Procedure called to validate IN_COUNT
	return true
}

proc update_PARAM_VALUE.OUT_BYTE_COUNT { PARAM_VALUE.OUT_BYTE_COUNT } {
	# Procedure called to update OUT_BYTE_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_BYTE_COUNT { PARAM_VALUE.OUT_BYTE_COUNT } {
	# Procedure called to validate OUT_BYTE_COUNT
	return true
}

proc update_PARAM_VALUE.OUT_WORD_COUNT { PARAM_VALUE.OUT_WORD_COUNT } {
	# Procedure called to update OUT_WORD_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_WORD_COUNT { PARAM_VALUE.OUT_WORD_COUNT } {
	# Procedure called to validate OUT_WORD_COUNT
	return true
}


proc update_MODELPARAM_VALUE.IN_COUNT { MODELPARAM_VALUE.IN_COUNT PARAM_VALUE.IN_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IN_COUNT}] ${MODELPARAM_VALUE.IN_COUNT}
}

proc update_MODELPARAM_VALUE.OUT_WORD_COUNT { MODELPARAM_VALUE.OUT_WORD_COUNT PARAM_VALUE.OUT_WORD_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_WORD_COUNT}] ${MODELPARAM_VALUE.OUT_WORD_COUNT}
}

proc update_MODELPARAM_VALUE.OUT_BYTE_COUNT { MODELPARAM_VALUE.OUT_BYTE_COUNT PARAM_VALUE.OUT_BYTE_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_BYTE_COUNT}] ${MODELPARAM_VALUE.OUT_BYTE_COUNT}
}

