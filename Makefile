
#------------------------------------------------------------------------------#
# Change your own verilog compiler.                                            #
#------------------------------------------------------------------------------#
#VERILOG=irun
#VERILOG=ncverilog
VERILOG=iverilog

#------------------------------------------------------------------------------#
# Directories Declarations                                                     #
#------------------------------------------------------------------------------#
CUR_DIR=$(PWD)
TB_DIR=tb
BUILD_DIR=build
SRC_DIR=src
INC_DIR=inc

test1:
	cd $(TB_DIR) && python3 matmul.py inputs1
#	$(VERILOG) tb/top_tb.v \
#    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR) +access+r
	iverilog -o simulation_output tb/top_tb.v -I $(PWD)/$(SRC_DIR) -I $(PWD)/$(TB_DIR) -I $(PWD)/$(BUILD_DIR)
	vvp simulation_output
test2:
	cd $(TB_DIR) && python3 matmul.py inputs2
#	$(VERILOG) tb/top_tb.v \
#    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR) +access+r
	iverilog -o simulation_output tb/top_tb.v -I $(PWD)/$(SRC_DIR) -I $(PWD)/$(TB_DIR) -I $(PWD)/$(BUILD_DIR)
	vvp simulation_output
test3:
	cd $(TB_DIR) && python3 matmul.py inputs3
#	$(VERILOG) tb/top_tb.v \
#    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR) +access+r
	iverilog -o simulation_output tb/top_tb.v -I $(PWD)/$(SRC_DIR) -I $(PWD)/$(TB_DIR) -I $(PWD)/$(BUILD_DIR)
	vvp simulation_output
monster:
	cd $(TB_DIR) && python3 matmul.py monster
#	$(VERILOG) tb/top_tb.v \
#    +incdir+$(PWD)/$(SRC_DIR)+$(PWD)/$(TB_DIR)+$(PWD)/$(BUILD_DIR) +access+r
	iverilog -o simulation_output tb/top_tb.v -I $(PWD)/$(SRC_DIR) -I $(PWD)/$(TB_DIR) -I $(PWD)/$(BUILD_DIR)
	vvp simulation_output
clean:
	rm -rf build
