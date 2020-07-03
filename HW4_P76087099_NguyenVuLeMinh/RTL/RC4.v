`timescale 1ns/10ps
module RC4(clk,rst,key_valid,key_in,plain_read,plain_in_valid,plain_in,plain_write,plain_out,cipher_write,cipher_out,cipher_read,cipher_in,cipher_in_valid,done);
    input   clk,rst;
    input   key_valid,plain_in_valid,cipher_in_valid;
    input   [7:0] key_in,cipher_in,plain_in;
    output  reg done;
    output  reg plain_write,cipher_write,plain_read,cipher_read;
    output  [7:0] cipher_out,plain_out;

    parameter   Length_Key         = 32;
    parameter   Length_Sbox        = 64;

    reg     [7:0]   data_key [0:Length_Key-1];   
    reg     [7:0]   Sbox_new     [0:Length_Sbox - 1];  
    reg     [7:0]   Sbox_new2     [0:Length_Sbox - 1];  
    reg     [2:0]   State;
    reg     [7:0]   index_key,index_sbox;
    reg     [7:0]   k1,k2;
    reg     [11:0]  value_total,value_total2;
    reg             flag_cipher_plain;

    wire    [7:0]   wire_index_i;

    assign wire_index_i    = k1 + 1;
    assign cipher_out      = plain_in ^ Sbox_new[value_total[5:0]];
    assign plain_out       = cipher_in ^ Sbox_new2[value_total2[5:0]];

    always @(posedge clk or posedge rst ) begin
        if (rst) begin
            State               <= 3'b000;
            k1                  <= 8'b0;
            k2                  <= 8'b0;
            plain_write         <= 1'b0;
            cipher_write        <= 1'b0;
            done                <= 1'b0;
            index_sbox          <=  8'b0;
            flag_cipher_plain   <= 1'b0;
        end
        else begin
            
            case(State)
                3'b000: begin // Key-scheduling
                    if (index_sbox == Length_Sbox) begin
                        State      <= 3'b001;
						k2         <= k2 + Sbox_new[k1] + data_key[k1[4:0]];
                    end
                    else begin
                        Sbox_new[index_sbox]    <= index_sbox;
                        Sbox_new2[index_sbox]   <= index_sbox;
                        index_sbox              <= index_sbox + 1;
                    end
                end
                3'b001: begin // Swap Key-scheduling
                    Sbox_new[k1]        <= Sbox_new[k2[5:0]];
                    Sbox_new[k2[5:0]]   <= Sbox_new[k1];
                    Sbox_new2[k1]       <= Sbox_new2[k2[5:0]];
                    Sbox_new2[k2[5:0]]  <= Sbox_new2[k1];
                    
                    if (k1 == Length_Sbox - 1)begin
                        State      <= 3'b010;
                        k1         <= 8'b0;
                        k2         <= 8'b0;
                    end
                    else begin
                        k1         <=  k1 + 1;
                        State      <=  3'b000;
						
                    end
                end
				3'b010:begin //Ecryption and Decryption algorithms
                    State           <= (!flag_cipher_plain)?3'b011:3'b100;
                    k1              <= wire_index_i;
                    cipher_write    <= 1'b0;
                    plain_write     <= 1'b0;
                   
                    if (!flag_cipher_plain) begin
                        k2          <= k2 + Sbox_new[wire_index_i[5:0]];
                        plain_read  <= 1'b1;
                    end
                    else begin
                        k2          <= k2 + Sbox_new2[wire_index_i[5:0]];	
                        cipher_read <= 1'b1;
                    end
				end
                3'b011:begin // Cipher (Ecryption)
                    State                 <= 3'b010;
                    Sbox_new[k1[5:0]]     <= Sbox_new[k2[5:0]];
                    Sbox_new[k2[5:0]]     <= Sbox_new[k1[5:0]];
                    value_total           <= Sbox_new[k1[5:0]] + Sbox_new[k2[5:0]];
                    plain_read            <= 1'b0;
                    cipher_write          <= 1'b1;
                    
                    if (!plain_in_valid && !flag_cipher_plain ) begin
                        k1                <= 0;
                        k2                <= 0;
                        flag_cipher_plain <= 1'b1;
                        cipher_write      <= 1'b0;
                     
                    end
                end
                3'b100:begin //Plain (Decryption)
                    State                <= 3'b010;
                    Sbox_new2[k1[5:0]]   <= Sbox_new2[k2[5:0]];
                    Sbox_new2[k2[5:0]]   <= Sbox_new2[k1[5:0]];
                    value_total2         <= Sbox_new2[k1[5:0]] + Sbox_new2[k2[5:0]];
                    cipher_read          <= 1'b0;
                    plain_write          <= 1'b1;
                  
                    if (!cipher_in_valid && flag_cipher_plain) begin
                        done <= 1;
                    end
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            index_key     <=  8'b0;
        end 
        else begin
            if (key_valid) begin
                if (index_key > Length_Key)begin
                    index_key <= 8'b0;
                end
                else begin
                    data_key[index_key-1]   <= key_in;
                    index_key               <= index_key+1;
                end
            end
        end
    end
endmodule














