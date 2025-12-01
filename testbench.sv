
`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  rand bit [7:0] data_in;
  bit [7:0] enc_out;
  bit [7:0] dec_out;
  bit [7:0] prng_used;
  
  function new(string name ="transaction");
    super.new(name);
  endfunction

endclass

class encry_seqr extends uvm_sequence#(transaction);
  `uvm_object_utils(encry_seqr)
  transaction tr;
  
  function new(string name ="encry_seqr");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(3) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      assert(tr.randomize());
      `uvm_info("SEQR", $sformatf("data_in %0d", tr.data_in), UVM_LOW);
      finish_item(tr);
    end
  endtask
  
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  virtual enc_if vif;
  transaction tr;
  
  function new(string path ="driver", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if (!uvm_config_db#(virtual enc_if)::get(null,"","vif",vif)) 
      `uvm_error("drv","Unable to access Interface"); 
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    #10;
    forever begin
      seq_item_port.get_next_item(tr);
      @(posedge vif.clk);
      vif.encrypt_en <= 1'b1;
      vif.data_in <= tr.data_in;
      `uvm_info("DRV", $sformatf("data_in %0d", tr.data_in), UVM_LOW);
      repeat(2) @(posedge vif.clk);
      vif.encrypt_en <= 1'b0;
      seq_item_port.item_done();
    end
  endtask

endclass

class sco extends uvm_scoreboard;
  `uvm_component_utils(sco)
   uvm_analysis_imp#(transaction, sco) recv;
  
    function new(string path ="sco", uvm_component parent = null);
      super.new(path, parent);
      recv = new("recv",this);
  endfunction
  
  virtual function void write(transaction tr);
    bit [7:0] enc_out, dec_out;
    enc_out = tr.prng_used ^ tr.data_in;
    dec_out = (tr.prng_used ^ tr.data_in) ^ tr.prng_used;
    `uvm_info("SCO", $sformatf("data in %0d enc %0d dec %0d prng_used %0d enc_out %0d dec out %0d", tr.data_in,tr.enc_out,tr.dec_out,tr.prng_used,enc_out,dec_out), UVM_LOW);
    if ((tr.enc_out == enc_out) && (tr.data_in == dec_out)) begin 
      `uvm_info("SCO", $sformatf("TEST PASSED data in %0d enc %0d dec %0d", tr.data_in,tr.enc_out,tr.dec_out), UVM_LOW);
    end
    else begin
      `uvm_info("SCO", $sformatf("TEST FAILED data in %0d enc %0d dec %0d", tr.data_in,tr.enc_out,tr.dec_out), UVM_LOW);
    end 
  endfunction
  
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  virtual enc_if vif;
  uvm_analysis_port#(transaction) send_mon;
  transaction tr;
  int i = 0;
  
  function new(string path ="monitor", uvm_component parent = null);
    super.new(path, parent);
    send_mon = new("send_mon",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual enc_if)::get(null,"","vif",vif)) 
      `uvm_error("mon","Unable to access Interface"); 
  endfunction
  
    virtual task run_phase(uvm_phase phase);
      #20;
      forever begin
        repeat(3) @(posedge vif.clk);
        tr = transaction::type_id::create("tr");
        tr.enc_out = vif.enc_data_out;
        tr.dec_out = vif.dec_data_out;
        tr.data_in = vif.data_in;
        tr.prng_used = vif.prng_used;
        `uvm_info("MON", $sformatf("data in %0d enc %0d dec %0d", tr.data_in,tr.enc_out,tr.dec_out), UVM_LOW)
        `uvm_info("MON", $sformatf("vif data in %0d enc %0d dec %0d prng %0d", vif.data_in,vif.enc_data_out,vif.dec_data_out, vif.prng_used), UVM_LOW)
        send_mon.write(tr);
      end
    endtask
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent)
  monitor m;
  driver d;
  uvm_sequencer #(transaction) seqr;
  
  function new(string path ="agent", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d = driver::type_id::create("d",this);
    m = monitor::type_id::create("m",this);
    seqr = uvm_sequencer #(transaction)::type_id::create("seqr",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
  
endclass

class env extends uvm_env;
  `uvm_component_utils(env)
  agent a;
  sco s;
  
  function new(string path ="env", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      a = agent::type_id::create("a",this);
      s = sco::type_id::create("s",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send_mon.connect(s.recv);
  endfunction
  
endclass

class enc_test extends uvm_test;
  `uvm_component_utils(enc_test)
  env e;
  encry_seqr enc_seqr;
  
  function new(string path ="enc_test", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = env::type_id::create("e",this);
    enc_seqr = encry_seqr::type_id::create("enc_seqr",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    enc_seqr.start(e.a.seqr);
    #500;
    phase.drop_objection(this);
  endtask
endclass

module tb_top();
  enc_if vif();
  
  top_encrypt enc_dut ( .rst_n(vif.rst_n), .clk(vif.clk), .load_seed(vif.load_seed), .seed_in(vif.seed_in), .encrypt_en(vif.encrypt_en), .data_in(vif.data_in), .enc_data_out(vif.enc_data_out), .dec_data_out(vif.dec_data_out), .prng_used(vif.prng_used));
 
  initial begin
    vif.clk <= 0;
    vif.rst_n <= 1;
    #10;
    vif.rst_n <= 0;
  end
  
  always #5 vif.clk <= ~vif.clk;
  
  initial begin
    uvm_config_db#(virtual enc_if)::set(null, "*", "vif", vif);
    run_test("enc_test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
