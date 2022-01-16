module fifo_prog #(
    parameter D_WIDTH = 31,
    parameter BUFF_WIDTH = 4
) (
    input clk,
    input reset,
    input new_prog,
    input inc_prog,
    input dec_prog,
    input write,
    input pop,
    input [D_WIDTH-1: 0] d,
    output [D_WIDTH-1: 0] q,
    output wire empty,
    output wire full
);
    reg [D_WIDTH-1: 0] data[(1 << BUFF_WIDTH) - 1: 0];
    reg [7:0] cnt [(1 << BUFF_WIDTH) - 1: 0];

    reg [BUFF_WIDTH-1:0] head, tail;
    wire [BUFF_WIDTH-1:0] head_next, tail_next;
    
    assign head_next = head + 1'b1,
            tail_next = tail + 1'b1;
    assign full = (head_next == tail)? 1'b1: 1'b0;
    assign empty = (head == tail)? 1'b1: 1'b0;
    assign q = data[tail];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tail <= 1;
            head <= 0;
            data[0] <= 0;
        end else begin

            if (new_prog & ~full) begin
                head <= head_next;
                cnt[head] <= 1;
            end

            if (inc_prog && dec_prog && (head == tail)) begin
                // khong doi
            end else begin
                if (inc_prog) begin
                    cnt[head] <= cnt[head] + 1'b1;
                end

                if (dec_prog) begin
                    cnt[tail] <= cnt[tail] - 1'b1;
                end
            end

        end
    end
endmodule