module ultrasonic_driver(
    input  clk,
    input  reset,          // active LOW reset
    input  echo_rx,
    output reg trig,
    output op,
    output wire [15:0] distance_out
);

// ---------------- PARAMETERS ----------------
localparam TRIG_TICKS      = 500;      // 10 us @ 50 MHz
localparam SETTLE_TICKS    = 50;       // 1 us
localparam WAIT_ECHO_TIMEOUT = 600000; // 12 ms
localparam ECHO_MAX_TICKS  = 600000;   // max valid echo
localparam RETRIG_DELAY    = 4000000;  // 60 ms (prevents cross-talk)

// FSM STATES
localparam FSM_IDLE        = 3'd0,
           FSM_SETTLE      = 3'd1,
           FSM_TRIG        = 3'd2,
           FSM_WAIT_ECHO_H = 3'd3,
           FSM_ECHO        = 3'd4,
           FSM_WAIT_RETRIG = 3'd5;

// ---------------- REGISTERS ----------------
reg [2:0]  state;
reg [31:0] counter;
reg [31:0] echo_ticks;
reg [15:0] distance_mm;
reg        op_reg;

// ---------------- FSM ----------------
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        state        <= FSM_IDLE;
        trig         <= 1'b0;
        counter      <= 0;
        echo_ticks   <= 0;
        distance_mm  <= 0;
        op_reg       <= 0;
    end 
    else begin

        case (state)

        // ---------------- IDLE ----------------
        FSM_IDLE: begin
            trig    <= 1'b0;
            counter <= 0;
            state   <= FSM_SETTLE;
        end

        // ---------------- SETTLE ----------------
        FSM_SETTLE: begin
            if (counter >= SETTLE_TICKS*2) begin
                counter <= 0;
                trig    <= 1'b1;
                state   <= FSM_TRIG;
            end 
            else begin
                counter <= counter + 1;
            end
        end

        // ---------------- TRIG ----------------
        FSM_TRIG: begin
            if (counter >= TRIG_TICKS) begin
                trig       <= 1'b0;
                counter    <= 0;
                echo_ticks <= 0;
                state      <= FSM_WAIT_ECHO_H;
            end 
            else begin
                counter <= counter + 1;
            end
        end

        // -------- WAIT FOR ECHO HIGH --------
        FSM_WAIT_ECHO_H: begin
            if (echo_rx) begin
                counter <= 0;
                state   <= FSM_ECHO;
            end else if (counter >= WAIT_ECHO_TIMEOUT) begin
                // timeout → no echo
                distance_mm <= 1000;
                op_reg      <= 0;
                counter     <= 0;
                state       <= FSM_WAIT_RETRIG;
            end 
            else begin
                counter <= counter + 1;
            end
        end

        // ---------------- ECHO ----------------
        FSM_ECHO: begin
            if (echo_rx) begin
                echo_ticks <= echo_ticks + 1;

                // Long echo → reject
                if (echo_ticks >= ECHO_MAX_TICKS) begin
                    distance_mm <= 1000;
                    op_reg      <= 0;
                    counter     <= 0;
                    state       <= FSM_WAIT_RETRIG;
                end

            end 
            else begin
                // echo ended → calculate distance
                distance_mm <= (echo_ticks * 7) >> 11;
                op_reg      <= (((echo_ticks * 7) >> 11) < 70);

                counter <= 0;
                state   <= FSM_WAIT_RETRIG;
            end
        end

        // ------------ WAIT BEFORE NEXT TRIG (prevents cross-talk) ------------
        FSM_WAIT_RETRIG: begin
            if (counter >= RETRIG_DELAY) begin
                counter <= 0;
                state   <= FSM_SETTLE;
            end 
            else begin
                counter <= counter + 1;
            end
        end

        default: state <= FSM_IDLE;

        endcase
    end
end

// ---------------- OUTPUTS ----------------
assign distance_out = distance_mm;
assign op = op_reg;

endmodule
