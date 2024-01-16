rows=4
col=4
sys=open("generated.sv",'w')
str=""
for i in range(rows):
    for j in range(col):
        #for control signals flowing downward
        if (i==0):
            W_en=f"wfetch[{j}]"
            W_ready=f"W_ready[{i}][{j}]"
            W_in=f"i_wdata[{j}]"
            W_out=f"W_data[{i}][{j}]"
            P_in=f"bias"
            P_out=f"P_data[{i}][{j}]"
        elif (i==rows-1):
            W_en=f"W_ready[{i-1}][{j}] & wfetch[{j}]"
            W_ready=f""
            W_in=f"W_data[{i-1}][{j}]"
            W_out=""
            P_in=f"P_data[{i-1}][{j}]"
            P_out=f"of_data[{j}]"        
        else:
            W_en=f"W_ready[{i-1}][{j}] & wfetch[{j}]"
            W_ready=f"W_ready[{i}][{j}]"
            W_in=f"W_data[{i-1}][{j}]"
            W_out=f"W_data[{i}][{j}]"
            P_in=f"P_data[{i-1}][{j}]"
            P_out=f"P_data[{i}][{j}]"
        #for control signals flowing rightward
        if (j==0):
            switch_in=f"W_switch[{i}][{j}]"
            switch_out=f"W_switch[{i}][{j+1}]"
            A_en=f"if_en[{i}]"
            A_ready=f"A_ready[{i}][{j}]"
            A_in=f"if_data[{i}]"
            A_out=f"A_data[{i}][{j}]"

        elif (j==col-1):
            switch_in=f"W_switch[{i}][{j}]"
            switch_out=f""
            A_en=f"A_ready[{i}][{j-1}]"
            A_ready=f""
            A_in=f"A_data[{i}][{j-1}]"
            A_out=f""
        else:
            switch_in=f"W_switch[{i}][{j}]"
            switch_out=f"W_switch[{i}][{j+1}]"
            A_en=f"A_ready[{i}][{j-1}]"
            A_ready=f"A_ready[{i}][{j}]"
            A_in=f"A_data[{i}][{j-1}]"
            A_out=f"A_data[{i}][{j}]"
        
        if (i==0 and j==0):
            switch_in=f"switch"
        str+=f"""mac mac_instance{i}{j} (
      .clk(clk),
      .rst(rst),
      .switch_in({switch_in}),
      .switch_out({switch_out}),
      .A_en({A_en}),
      .A_ready({A_ready}),
      .A_in({A_in}),
      .A_out({A_out}),
      .W_en({W_en}),
      .W_ready({W_ready}),
      .W_in({W_in}),
      .W_out({W_out}),
      .P_in({P_in}),
      .P_out({P_out})
  );\n"""
sys.write(str)
sys.close()

