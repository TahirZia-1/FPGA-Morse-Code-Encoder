module debouncer(
    input wire clk,
    input wire btn_in,
    output reg btn_out
);
    reg [19:0] counter;
    reg btn_prev;
    
    initial begin
        counter = 0;
        btn_prev = 0;
        btn_out = 0;
    end
    
    always @(posedge clk) begin
        if (btn_in != btn_prev) begin
            counter <= 0;
            btn_prev <= btn_in;
        end
        else if (counter < 1000000) begin  // 10ms debounce at 100MHz
            counter <= counter + 1;
        end
        else begin
            btn_out <= btn_prev;
        end
    end
endmodule

module morse_encoder(
    input wire clk,
    input wire btn0,
    input wire btn1,
    input wire btn2,
    input wire mode,
    input wire [3:0] switches,
    output reg led,
    output wire state_led
);
    // States for the FSM
    localparam IDLE = 0;
    localparam ENCODING_DIGIT = 1;
    localparam INTER_DIGIT_GAP = 2;
    
    // Morse code patterns
    reg [4:0] morse_pattern;
    reg [2:0] pattern_length;
    
    // Timing constants (100MHz clock)
    localparam DOT_CYCLES = 100_000_000;       // 1 second
    localparam DASH_CYCLES = 300_000_000;     // 3 seconds
    localparam SPACE_CYCLES = 50_000_000;     // 0.5 seconds
    localparam INTER_DIGIT_CYCLES = 200_000_000; // 2 seconds
    
    // Storage registers
    reg [31:0] counter;
    reg [2:0] current_element;
    reg [1:0] current_state;
    reg is_space;
    reg btn1_prev, btn2_prev;
    reg latched_mode;
    
    // FIFO registers
    reg [3:0] fifo [0:5];
    reg [2:0] write_ptr;
    reg [2:0] digit_count;
    reg [2:0] current_digit;
    reg [3:0] temp_digit;
    
    assign state_led = current_state != IDLE;

    // Initialize Morse pattern
    always @(*) begin
        case(latched_mode ? fifo[current_digit] : temp_digit)
            4'b0000: begin  // 0
                morse_pattern = 5'b00000;
                pattern_length = 5;
            end
            4'b0001: begin  // 1
                morse_pattern = 5'b10000;
                pattern_length = 5;
            end
            4'b0010: begin  // 2
                morse_pattern = 5'b11000;
                pattern_length = 5;
            end
            4'b0011: begin  // 3
                morse_pattern = 5'b11100;
                pattern_length = 5;
            end
            4'b0100: begin  // 4
                morse_pattern = 5'b11110;
                pattern_length = 5;
            end
            4'b0101: begin  // 5
                morse_pattern = 5'b11111;
                pattern_length = 5;
            end
            4'b0110: begin  // 6
                morse_pattern = 5'b01111;
                pattern_length = 5;
            end
            4'b0111: begin  // 7
                morse_pattern = 5'b00111;
                pattern_length = 5;
            end
            4'b1000: begin  // 8
                morse_pattern = 5'b00011;
                pattern_length = 5;
            end
            4'b1001: begin  // 9
                morse_pattern = 5'b00001;
                pattern_length = 5;
            end
            default: begin
                morse_pattern = 5'b00000;
                pattern_length = 0;
            end
        endcase
    end

    // Main logic
    always @(posedge clk or posedge btn0) begin
        if (btn0) begin
            // Reset all registers
            led <= 0;
            counter <= 0;
            current_element <= 0;
            current_state <= IDLE;
            is_space <= 0;
            btn1_prev <= 0;
            btn2_prev <= 0;
            write_ptr <= 0;
            digit_count <= 0;
            current_digit <= 0;
            temp_digit <= 0;
            latched_mode <= 0;
            for (integer i = 0; i < 6; i = i+1) fifo[i] <= 0;
        end
        else begin
            btn1_prev <= btn1;
            btn2_prev <= btn2;
            
            // Store digits in number mode
            if (mode && btn1 && !btn1_prev && digit_count < 6) begin
                fifo[write_ptr] <= switches;
                write_ptr <= write_ptr + 1;
                digit_count <= digit_count + 1;
            end
            
            case (current_state)
                IDLE: begin
                    led <= 0;
                    if (!mode && btn1 && !btn1_prev) begin  // Digit mode
                        temp_digit <= switches;
                        latched_mode <= 0;
                        current_state <= ENCODING_DIGIT;
                        current_digit <= 0;
                        digit_count <= 1;
                        counter <= 0;
                        current_element <= 0;
                        is_space <= 0;
                    end
                    else if (mode && btn2 && !btn2_prev && digit_count > 0) begin  // Number mode
                        latched_mode <= 1;
                        current_state <= ENCODING_DIGIT;
                        current_digit <= 0;
                        counter <= 0;
                        current_element <= 0;
                        is_space <= 0;
                    end
                end
                
                ENCODING_DIGIT: begin
                    if (current_element < pattern_length) begin
                        if (!is_space) begin
                            led <= 1;
                            if (morse_pattern[pattern_length - 1 - current_element]) begin
                                if (counter >= DOT_CYCLES - 1) begin
                                    counter <= 0;
                                    is_space <= 1;
                                end
                                else counter <= counter + 1;
                            end
                            else begin
                                if (counter >= DASH_CYCLES - 1) begin
                                    counter <= 0;
                                    is_space <= 1;
                                end
                                else counter <= counter + 1;
                            end
                        end
                        else begin
                            led <= 0;
                            if (counter >= SPACE_CYCLES - 1) begin
                                counter <= 0;
                                is_space <= 0;
                                current_element <= current_element + 1;
                            end
                            else counter <= counter + 1;
                        end
                    end
                    else begin
                        led <= 0;
                        if (current_digit < digit_count - 1) begin
                            current_state <= INTER_DIGIT_GAP;
                            counter <= 0;
                        end
                        else current_state <= IDLE;
                    end
                end
                
                INTER_DIGIT_GAP: begin
                    led <= 0;
                    if (counter >= INTER_DIGIT_CYCLES - 1) begin
                        counter <= 0;
                        current_digit <= current_digit + 1;
                        current_element <= 0;
                        is_space <= 0;
                        current_state <= ENCODING_DIGIT;
                    end
                    else counter <= counter + 1;
                end
            endcase
        end
    end
endmodule

module morse_top(
    input wire clk,              // 100MHz clock
    input wire btn0,             // Reset (BTNC)
    input wire btn1,             // Start/Store (BTNL)
    input wire btn2,             // Encode Number (BTNR)
    input wire [4:0] switches,   // SW4: mode, SW3-0: digit
    output wire led,             // LD0
    output wire state_led        // LD1
);
    wire btn0_db, btn1_db, btn2_db;
    
    debouncer db0 (.clk(clk), .btn_in(btn0), .btn_out(btn0_db));
    debouncer db1 (.clk(clk), .btn_in(btn1), .btn_out(btn1_db));
    debouncer db2 (.clk(clk), .btn_in(btn2), .btn_out(btn2_db));
    
    morse_encoder encoder(
        .clk(clk),
        .btn0(btn0_db),
        .btn1(btn1_db),
        .btn2(btn2_db),
        .mode(switches[4]),
        .switches(switches[3:0]),
        .led(led),
        .state_led(state_led)
    );
endmodule