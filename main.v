module ram_file(input write, input [7:0] address, input [31:0] write_value, output reg [7:0] o1, o2, o3, o4, input [7:0] read_addr, input clock);
    // ram is byte addressable
    reg [7:0] ram [0:255];
    
    integer i;  
    always @(posedge clock) begin
        if (write) begin
            ram[address]     <= write_value[7:0];
            ram[address + 1] <= write_value[15:8];
            ram[address + 2] <= write_value[23:16];
            ram[address + 3] <= write_value[31:24];
        end

        o1 <= ram[read_addr];
        o2 <= ram[read_addr + 1];
        o3 <= ram[read_addr + 2];
        o4 <= ram[read_addr + 3];
    end

    initial begin
        
        for (i =0; i < 255; i+=1) begin
            ram[i] = 0;
        end
        o1 =0;
        o2 =0;
        o3 =0;
        o4 =0;
    end

endmodule

module register_file(input save, input immediate, input load, 
                    input [1:0] addr1, input [1:0] addr2, input [7:0] immediate_value,
                    output reg [7:0] out1, out2, 
                    input clock);
    // if save is on, saves register of addr2 into addr1. If immediate is also on, saves immediate input instead.
    // if load is on, loads register of addr1 into out1 and addr2 to out2 

    reg [7:0] regs [0:3];

    always @(posedge clock) begin
    
        if (save) begin
            
            if (immediate) begin
                regs[addr1] <= immediate_value;
            end else begin
                regs[addr1] <= regs[addr2];
            end

        end
        if (load) begin
            out1 <= regs[addr1];
            out2 <= regs[addr2];
        end
    
    end

    integer i;
    initial begin
        for (i = 0; i < 4; i = i + 1)
            regs[i] = 0;
        out1 = 0;
        out2 = 0;
    end

endmodule

module CPU();
    reg clock =0; // cpu clock
    reg [7:0] counter = 0; // ram counter


    // register file
    reg reg_save, reg_immediate, reg_load;
    reg [1:0] reg_addr1, reg_addr2;
    reg [7:0] reg_immediate_value;
    wire [7:0] reg_bus1, reg_bus2;
    register_file regfile(.save(reg_save), .immediate(reg_immediate), .load(reg_load),
                             .addr1(reg_addr1), .addr2(reg_addr2), .immediate_value(reg_immediate_value),
                             .out1(reg_bus1), .out2(reg_bus2), .clock(clock));


    // ram file
    wire [7:0] ram_o1, ram_o2, ram_o3, ram_o4; // ram outputs
    reg ram_write;
    reg [7:0] ram_write_addr;
    reg [31:0] ram_write_value;
    ram_file ramfile(.write(ram_write), .address(ram_write_addr), .write_value(ram_write_value), 
                    .o1(ram_o1), .o2(ram_o2), .o3(ram_o3), .o4(ram_o4), 
                    .clock(clock), .read_addr(counter)); // ram block

    // cpu clock pulse
    reg [1:0] state = 0;
    reg [7:0] instr_o1, instr_o2, instr_o3, instr_o4;

    always @(posedge clock) begin
        case (state)
            0: begin
                // Fetch instruction
                instr_o1 <= ram_o1;
                instr_o2 <= ram_o2;
                instr_o3 <= ram_o3;
                instr_o4 <= ram_o4;
                state <= 1;
            end
            1: begin
                // Decode and execute
                case (instr_o1)
                    8'b0000_0001: begin // add reg
                        reg_save <= 1;
                        reg_load <= 1;
                        reg_immediate <= 1;

                        reg_addr1 <= instr_o2;
                        reg_addr2 <= instr_o3;
                        reg_immediate_value <= reg_bus1 + reg_bus2;
                    end
                    8'b1000_0001: begin // addi reg, reg, imm
                        reg_save <= 1;
                        reg_load <= 1;
                        reg_immediate <= 1;

                        reg_addr1 <= instr_o2;
                        reg_addr2 <= instr_o3;
                        reg_immediate_value <= reg_bus1 + instr_o4;
                    end
                    8'b0000_0010: begin // mov reg, reg
                        reg_save <= 1;
                        reg_addr1 <= instr_o2;
                        reg_addr2 <= instr_o3;
                    end
                endcase

                counter <= counter + 4;
                state <= 0;
            end
        endcase
    end


    always #2 clock = ~clock;

    initial begin
        $monitor("counter=%d, o1=%d, o2=%d, o3=%d, o4=%d, reg_bus1=%d, reg_bus2=%d \n\n", counter, ram_o1, ram_o2, ram_o3, ram_o4, reg_bus1, reg_bus2);
        
        // addi ram_file[1], ram_file[2], ram_file[3]
        ram_write = 1'b1;
        ram_write_value = {8'b0000_0011, 8'b0000_0000, 8'b0000_0000, 8'b1000_0001};
        ram_write_addr = 0;

        #100 $finish;
    end

endmodule