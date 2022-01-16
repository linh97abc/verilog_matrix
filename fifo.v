module fifo__ #(
    parameter D_WIDTH = 31,
    parameter BUFF_WIDTH = 4,
    parameter WRITE_SIGNAL = 0
) (
    input clk,
    input reset,
    input write,
    input push,
    input pop,
    input [D_WIDTH-1: 0] d,
    output [D_WIDTH-1: 0] q,
    output wire empty,
    output wire full
);
    reg [D_WIDTH-1: 0] data[(1 << BUFF_WIDTH) - 1: 0];

    reg [BUFF_WIDTH-1:0] head, tail;
    wire [BUFF_WIDTH-1:0] head_next, tail_next;
    
    assign head_next = head + 1'b1,
            tail_next = tail + 1'b1;
    assign full = (head_next == tail)? 1'b1: 1'b0;
    assign empty = (head == tail)? 1'b1: 1'b0;
    assign q = data[tail];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tail <= 0;
            head <= 0;
            data[0] <= 0;
        end else begin
            if (pop & ~empty) begin
                tail <= tail_next;
            end

            if (push & ~full) begin
                data[head] <= d;
                head <= head_next;
            end

        end
    end

    generate
        if (WRITE_SIGNAL) begin
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                end else begin
                    if (write & ~push) begin
                        data[head] <= d;
                    end
                end
            end
        end
    endgenerate
endmodule