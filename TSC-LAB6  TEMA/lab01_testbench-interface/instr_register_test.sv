/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/
import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv
module instr_register_test #(parameter MODE=0, NUMBER_OF_TRANSACTIONS=10, SEED=555, TEST_NAME = "DEFAULT NAME")
  
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );

  timeunit 1ns/1ns;
  int seed = SEED;
  initial begin
    // $display("\n\n***********************************************************");
    // $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    // $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    // $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    // $display(    "***********************************************************");
    // $display("  TEST_NAME = %s", TEST_NAME);
    // $display("  SEEED = %d", SEED);
    // $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles
    reset_n        = 1'b1;          // deassert reset_n (active low)

    // $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register
    repeat (NUMBER_OF_TRANSACTIONS) begin
      @(posedge clk) randomize_transaction;
      // @(negedge clk) print_transaction;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    // $display("\n Testing");
    for (int i=0; i<=NUMBER_OF_TRANSACTIONS; i++) begin
      if (MODE == 0 || MODE == 2)
        @(posedge clk) read_pointer = i;
      else
        @(posedge clk) read_pointer = $unsigned($random(seed))%32;
        @(negedge clk) begin
          // print_results;
          if (!CheckResult()) begin
             $display("\n '%s' => Test failed Result: %0d Expected:%0d",TEST_NAME, instruction_word.result,GetResult());
             $finish;
          end  
      end
    end
   $display("\n '%s' => Test passed", TEST_NAME);
    @(posedge clk) ;
    // $display("\n***********************************************************");
    // $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    // $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    // $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    // $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0;
    operand_a     <= $random(seed)%16;                 // between -15 and 15
    operand_b     <= $unsigned($random(seed))%16;            // between 0 and 15  
    opcode        <= opcode_t'($unsigned($random(seed))%8);  // between 0 and 7, cast to opcode_t type
    if (MODE == 0 || MODE == 1)
       write_pointer <= write_pointer + 1;
    else
       write_pointer <= $unsigned($random(seed))%32;
  endfunction: randomize_transaction

  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d\n", instruction_word.op_b);
    $display("  result = %0d\n", instruction_word.result);
  endfunction: print_results

  function automatic bit CheckResult;
    int expected_result;
    int actual_result;
    // Calculate result based on opcode and operands
      actual_result = GetResult();
    
    // Compare results
    expected_result = instruction_word.result;
    if (actual_result == expected_result) begin
        return 1;
    end else begin
        return 0;
    end
  endfunction: CheckResult

  function int GetResult;
   int actual_result;
   case (instruction_word.opc) 
        PASSA: actual_result = instruction_word.op_a;
        PASSB: actual_result = instruction_word.op_b;
        ADD: actual_result = instruction_word.op_a + instruction_word.op_b;
        SUB: actual_result = instruction_word.op_a - instruction_word.op_b;
        MULT: actual_result = instruction_word.op_a * instruction_word.op_b;
        DIV: actual_result = instruction_word.op_a / instruction_word.op_b;
        MOD: actual_result = instruction_word.op_a % instruction_word.op_b;
        default: actual_result = 0;
    endcase
    return actual_result;
  endfunction: GetResult
  
endmodule: instr_register_test
