module prng(input rst_n,
           input clk,
           input load_seed,
           input [7:0] seed_in,
           input encrypt_en,
           output reg [7:0] prng);
  
  localparam SEED = 8'hCD;
  wire feedback;
  assign feedback = prng[7] ^ prng[5] ^ prng[4] ^ prng[3];
  
  always@(posedge clk) begin
    if (rst_n)
      prng <= SEED;
    else if (load_seed == 1'b1)
      prng <= seed_in;
    else if (encrypt_en)
      prng <= {prng[6:0], feedback};
  end
  
endmodule

module top_encrypt(input rst_n,
                  input clk,
                  input load_seed,
                  input [7:0] seed_in,
                  input encrypt_en,
                  input [7:0] data_in,
                   output reg [7:0] enc_data_out,
                   output reg [7:0] dec_data_out,
                   output reg [7:0] prng_used);
  
  wire [7:0] prng;
  reg encrypt_dly;
  reg [7:0] din_dly;
  reg [7:0] prng_now;
  
  prng prng_dut (rst_n, clk, load_seed, seed_in, encrypt_en, prng);
  
  always @(posedge clk) begin
    if (rst_n) begin
      din_dly <= 0;
      encrypt_dly <= 0;
    end else begin
      encrypt_dly <= encrypt_en;
      din_dly <= data_in;
    end
  end
  
  always @(posedge clk) begin
    if (rst_n) begin
      enc_data_out <= 0;
      dec_data_out <= 0;
    end
    else if (encrypt_dly) begin 
      prng_now = prng;
      prng_used = prng_now;
      enc_data_out[7:0] <= prng_now[7:0] ^ din_dly[7:0];
      dec_data_out[7:0] <= (prng_now[7:0] ^ din_dly[7:0]) ^ prng_now[7:0];
    end
  end
  
endmodule

interface enc_if;
  logic rst_n;
  logic clk;
  logic load_seed;
  logic [7:0] seed_in;
  logic encrypt_en;
  logic [7:0] data_in;
  logic [7:0] enc_data_out;
  logic [7:0] dec_data_out;
  logic [7:0] prng_used;
endinterface
