module interrupt_controller (
    input  wire        clk,
    input  wire        reset_in,

    input  wire        intr,

    input  wire [7:0]  pc_push_data,
    input  wire [7:0]  ccr_push_data,

    input  wire        push_ack,
    input  wire        read_isr_valid,
    input  wire [7:0]  read_isr_data,

    output reg         start_push_pc,
    output reg         start_push_ccr,
    output reg         start_read_isr,
    output reg         interrupt_flush,
    output reg         busy,
    output reg         done,
    output reg  [7:0]  isr_value
);

localparam S_IDLE     = 4'd0;
localparam S_FLUSH    = 4'd1;
localparam S_PUSH_PC  = 4'd2;
localparam S_WAIT_PC  = 4'd3;
localparam S_PUSH_CC  = 4'd4;
localparam S_WAIT_CC  = 4'd5;
localparam S_READ_ISR = 4'd6;
localparam S_WAIT_ISR = 4'd7;
localparam S_DONE     = 4'd8;

reg [3:0] state, next_state;
reg intr_prev;

always @(posedge clk or posedge reset_in) begin
    if (reset_in) intr_prev <= 1'b0;
    else intr_prev <= intr;
end

always @(*) begin
    start_push_pc   = 1'b0;
    start_push_ccr  = 1'b0;
    start_read_isr  = 1'b0;
    interrupt_flush = 1'b0;
    done            = 1'b0;
    busy            = (state != S_IDLE);
    next_state      = state;

    case (state)
        S_IDLE: begin
            if (intr & ~intr_prev)
                next_state = S_FLUSH;
        end

        S_FLUSH: begin
            interrupt_flush = 1'b1;
            next_state = S_PUSH_PC;
        end

        S_PUSH_PC: begin
            start_push_pc = 1'b1;
            next_state = S_WAIT_PC;
        end

        S_WAIT_PC: begin
            if (push_ack) next_state = S_PUSH_CC;
        end

        S_PUSH_CC: begin
            start_push_ccr = 1'b1;
            next_state = S_WAIT_CC;
        end

        S_WAIT_CC: begin
            if (push_ack) next_state = S_READ_ISR;
        end

        S_READ_ISR: begin
            start_read_isr = 1'b1;
            next_state = S_WAIT_ISR;
        end

        S_WAIT_ISR: begin
            if (read_isr_valid) next_state = S_DONE;
        end

        S_DONE: begin
            done = 1'b1;
            next_state = S_IDLE;
        end
    endcase
end

always @(posedge clk or posedge reset_in) begin
    if (reset_in) begin
        state     <= S_IDLE;
        isr_value <= 8'h00;
    end else begin
        state <= next_state;
        if (read_isr_valid)
            isr_value <= read_isr_data;
    end
end
endmodule
