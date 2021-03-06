`define NULL 0
`define TEST_FILE_NAME "test/addiu.x"

module tb_final;

    // For arm_memory:
    reg        clk;
    reg [31:0] inst_addr;
    reg [31:0] mem_addr;
    reg [31:0] mem_data_in;
    reg        mem_write_en;
    wire [0:1]  excpt;
    wire [31:0] inst;
    wire [31:0] mem_data_out;

    wire [0:1] we;
    assign we[0] = 1'b0;
    assign we[1] = mem_write_en;

    // For arm_core:
    reg rst;
    wire halted;
    wire [31:0] mem_addr1, inst_addr1, mem_data_in1;
    wire  mem_write_en1;

    always @(*) begin
        mem_addr = (rst) ? mem_addr : mem_addr1;
        inst_addr = (rst) ? inst_addr : inst_addr1;
        mem_data_in = (rst) ? mem_data_in : mem_data_in1;
        mem_write_en = (rst) ? mem_write_en : mem_write_en;
    end

    arm_memory memauri
    (
        // Inputs
        .clk(clk),
        .addr1(inst_addr),
        .addr2(mem_addr),
        .data_in1(0),
        .data_in2(mem_data_in),
        .we(we),
        // Outputs
        .excpt(excpt),
        .data_out1(inst),
        .data_out2(mem_data_out)
    );

    arm_core core
    (
        // Inputs
        .clk(clk),
        .rst(rst),
        .inst(inst),
        .mem_data_out(mem_data_out),
        // Outputs
        .halted(halted),
        .mem_addr(mem_addr1),
        .inst_addr(inst_addr1),
        .mem_data_in(mem_data_in1),
        .mem_write_en(mem_write_en1)
    );

    always #10 clk = ~clk;

    integer index;
    integer text_file, scan_file;

    initial begin
        index = 0;
        clk = 0;
        rst = 1;
        text_file = $fopen(`TEST_FILE_NAME, "r");

        if (text_file == `NULL) begin
            $display("bad bad | text file handle was NULL");
            $finish;
        end
    end

    always @(negedge clk) begin
        scan_file = $fscanf(text_file, "%x\n", mem_data_in);
        if (scan_file != -1) begin
            $display("read from file: %x, trying to write to: %d",
                mem_data_in, index);
            mem_write_en = 0; //not ready to write yet.
            mem_addr = index;
            mem_write_en = 1;
            index = index + 4;
        end
        else begin
            rst = 0;
            if (halted)
                #10 $finish;
        end
    end

    /*always @(mem_data_out) begin
        $display("addr: %d, data: %x", mem_addr, mem_data_out);
    end*/

endmodule
