module fifo_2 #(
    parameter D_WIDTH = 31,
    parameter BUFF_WIDTH = 4
) (
    input clk,
    input reset,
    input push1, push2,
    input [D_WIDTH-1: 0] d1, d2,
    output [D_WIDTH-1: 0] q1, q2,
    output reg req
);
    reg [D_WIDTH-1: 0] data[(1 << BUFF_WIDTH) - 1: 0];

    reg [BUFF_WIDTH-1:0] head, tail;
    wire [BUFF_WIDTH-1:0] head_next, tail_next;
    
    assign head_next = head + 1'b1,
            tail_next = tail + 1'b1;

    wire [BUFF_WIDTH-1:0] distance;
    assign distance = head - tail;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tail <= 0;
            head <= 0;
            data[0] <= 0;
            req <= 1'b0;
        end else begin
            if (distance >= 2) begin
                tail <= tail + 2'b10;
                q1 <= data[tail];
                q2 <= data[tail_next];
                req <= 1'b1;
            end else begin
                req <= 1'b0;
            end

            case ({push1, push2})
                2'b01: begin
                    data[head] <= d2;
                    head <= head_next;
                end 
                2'b10: begin
                    data[head] <= d1;
                    head <= head_next;
                end
                2'b11: begin
                    data[head] <= d1;
                    data[head_next] <= d2;
                    head <= head + 2'b10;
                end
                default: begin
                    
                end 
            endcase
        end
    end
endmodule