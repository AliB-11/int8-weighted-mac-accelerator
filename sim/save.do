
mem save -o SRAM.mem -f mti -data hex -addr hex -startaddress 0 -endaddress 262143 -wordsperline 8 /TB/SRAM_component/SRAM_data

mem save -o TRAM.mem -f mti -data decimal -addr hex -startaddress 0 -endaddress 63 -wordsperline 8 /TB/UUT/M2_unit/RAM_inst2/altsyncram_component/m_default/altsyncram_inst/mem_data

mem save -o CS_RAM.mem -f mti -data decimal -addr hex -startaddress 0 -endaddress 63 -wordsperline 8 /TB/UUT/M2_unit/RAM_inst3/altsyncram_component/m_default/altsyncram_inst/mem_data