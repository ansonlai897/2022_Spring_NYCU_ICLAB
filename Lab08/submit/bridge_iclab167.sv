
module bridge(input clk, INF.bridge_inf inf);
//================================================================
// logic 
//================================================================

//================================================================
// state 
//================================================================
typedef enum logic [3:0] {
    IDLE, 
    // Write
    WR_AW_VALID,
    WR_W_VALID,
    WR_B_VALID,
    WR_RESET,
    // Read
    RD_AR_VALID,
    RD_R_VALID,
    RD_OUT_VALID,
    RD_RESET

    } state_t;
state_t current_state, next_state;


//================================================================
//   FSM
//================================================================
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) current_state <= IDLE;
    else            current_state <= next_state;
end
always_comb begin
    case(current_state)
        IDLE: begin
            if(inf.C_in_valid) begin
                if(inf.C_r_wb)
                    next_state = RD_AR_VALID;
                else
                    next_state = WR_AW_VALID;
            end
            else
                next_state = current_state;
        end
        WR_AW_VALID: begin
            if(inf.AW_READY)
                next_state = WR_W_VALID;
            else
                next_state = current_state;
        end
        WR_W_VALID: begin
            if(inf.W_READY)
                next_state = WR_B_VALID;
            else
                next_state = current_state;
        end
        WR_B_VALID: begin
            if(inf.B_VALID) 
                next_state = WR_RESET;
            else
                next_state = current_state;
        end
        WR_RESET: begin
            next_state = IDLE;
        end
        RD_AR_VALID: begin
            if(inf.AR_READY)
                next_state = RD_R_VALID;
            else
                next_state = current_state;
        end
        RD_R_VALID: begin
            if(inf.R_VALID)
                next_state = RD_OUT_VALID;
            else
                next_state = current_state;
        end
        RD_OUT_VALID: begin
            next_state = RD_RESET;
        end
        RD_RESET: begin
            next_state = IDLE;
        end
        default: begin
            next_state = current_state;
        end
    endcase
end
//================================================================
// design 
//================================================================
//===============================================================================================
// Write 
//===============================================================================================
//================================================================
// Write address channel
//================================================================
// AW_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AW_VALID <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.AW_VALID <= 0;
            WR_AW_VALID:    inf.AW_VALID <= 1;
            default:        inf.AW_VALID <= 0;
        endcase
    end           
end

// AW_ADDR
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AW_ADDR <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.AW_ADDR <= 0;
            WR_AW_VALID:    inf.AW_ADDR <= 65536 + 8 * inf.C_addr;
            default:        inf.AW_ADDR <= 0;
        endcase
    end           
end
//================================================================
// Write data channel
//================================================================
// W_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.W_VALID <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.W_VALID <= 0;
            WR_W_VALID:     inf.W_VALID <= 1;
            default:        inf.W_VALID <= 0;
        endcase
    end           
end

// W_DATA
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.W_DATA <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.W_DATA <= 0;
            WR_W_VALID:     inf.W_DATA <= inf.C_data_w;
            default:        inf.W_DATA <= 0;
        endcase
    end           
end
//================================================================
// Write response channel
//================================================================
// B_READY
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.B_READY <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.B_READY <= 0;
            WR_W_VALID:     inf.B_READY <= 1;
            WR_B_VALID:     inf.B_READY <= 1;
            default:        inf.B_READY <= 0;
        endcase
    end           
end
//===============================================================================================
// Read 
//===============================================================================================
//================================================================
// Read address channel
//================================================================
// AR_VALID
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_VALID <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.AR_VALID <= 0;
            RD_AR_VALID:    inf.AR_VALID <= 1;
            default:        inf.AR_VALID <= 0;
        endcase
    end           
end

// AR_ADDR
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_ADDR <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.AR_ADDR <= 0;
            RD_AR_VALID:    inf.AR_ADDR <= 65536 + 8 * inf.C_addr;
            default:        inf.AR_ADDR <= 0;
        endcase
    end           
end
//================================================================
// Read data channel
//================================================================
// R_READY
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.R_READY <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.R_READY <= 0;
            RD_R_VALID:     inf.R_READY <= 1;
            default:        inf.R_READY <= 0;
        endcase
    end           
end

// C_data_r
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.C_data_r <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.C_data_r <= 0;
            RD_OUT_VALID:   inf.C_data_r <= inf.R_DATA;
            default:        inf.C_data_r <= 0;
        endcase
    end           
end
//================================================================
// out valid 
//================================================================
// C_out_valid
always_ff@(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.C_out_valid <= 0;
    end
    else begin
        case(next_state)
            IDLE:           inf.C_out_valid <= 0;
            WR_RESET:       inf.C_out_valid <= 1;
            RD_OUT_VALID:   inf.C_out_valid <= 1;
            default:        inf.C_out_valid <= 0;
        endcase
    end           
end
endmodule