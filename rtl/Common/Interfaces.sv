interface Axi_stream_no_ready #(
    parameter type data_type = logic [7:0]
);

  data_type axi_data;
  logic axi_valid;  // Indicates that axi_data is valid

  modport slave(input axi_data, axi_valid);
  modport master(output axi_data, axi_valid);

endinterface
