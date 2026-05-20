----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:36:47 04/07/2026 
-- Design Name: 
-- Module Name:    debouncing - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
-- Import essential libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Inputs and outputs
entity debounce is
    Port ( 
            -- Clock (input)
			clk : in STD_LOGIC;
			
			-- Confirmation button (input)
            B0 : in  STD_LOGIC;

            -- Slide switches (input)
            A0 : in  STD_LOGIC;
            A1 : in  STD_LOGIC;
            A2 : in  STD_LOGIC;
            A3 : in  STD_LOGIC;

            -- Operation result LEDs (output)
            A0_out : out  STD_LOGIC;
            A1_out : out  STD_LOGIC;
            A2_out : out  STD_LOGIC;
            A3_out : out  STD_LOGIC;

            -- Flag LEDs (output)
            S0_out : out  STD_LOGIC;
            S1_out : out  STD_LOGIC;
            S2_out : out  STD_LOGIC;
            S3_out : out STD_LOGIC);
end debounce;

-- Architecture behavioral
architecture Behavioral of debounce is

-- Signals related to the button debounce feature
signal b0_sync : std_logic_vector(1 downto 0);
signal count : integer range 0 to 1_000_000 := 0;
signal b0_deb : std_logic := '0';

-- Signals related to the ALU state variable
signal state_id : integer range 0 to 3 := 0;
signal state : std_logic_vector(2 downto 0) := "000";

-- Signals related to the A (4 bit) input
signal inA0 : std_logic := '0';
signal inA1 : std_logic := '0';
signal inA2 : std_logic := '0';
signal inA3 : std_logic := '0';

-- Signals related to the operator input
signal inOp0 : std_logic := '0';
signal inOp1 : std_logic := '0';
signal inOp2 : std_logic := '0';

-- Signals related to the B (4 bit) input
signal inB0 : std_logic := '0';
signal inB1 : std_logic := '0';
signal inB2 : std_logic := '0';
signal inB3 : std_logic := '0';

-- Signals related to the ~B (4 bit) input
signal inNB0 : std_logic := '0';
signal inNB1 : std_logic := '0';
signal inNB2 : std_logic := '0';
signal inNB3 : std_logic := '0';

-- Signals related to the carry out
signal cout0 : std_logic := '0';
signal cout1 : std_logic := '0';
signal cout2 : std_logic := '0';
signal cout3 : std_logic := '0';

-- Signals related to the other output flags
signal zero : std_logic := '0';
signal ngtv  : std_logic := '0';
signal ovflw : std_logic := '0';

-- Signals related to the operation result output
signal outS0 : std_logic := '0';
signal outS1 : std_logic := '0';
signal outS2 : std_logic := '0';
signal outS3 : std_logic := '0';


begin
    -- Button debounce process 
	process(clk)
	begin
	    -- On clock rising edge:
		if rising_edge(clk) then
		    -- Sync signal and button read
			b0_sync <= b0_sync(0) & B0;

			-- Compare current state with stored state
			if (b0_sync(1) /= b0_deb) then
			    -- Verifies if button has been pressed for long time enough
                -- If pressed for less than 10^6 clock cycles, increment
				if (count < 1_000_000) then
					count <= count + 1;
                -- If pressed for long time enough, store button signal
				else
					b0_deb <= b0_sync(1);
					count <= 0;
				end if;
			else
				count <= 0;
			end if;

			-- Changes state_id if button has been pressed
			if (b0_sync(1) = '1' and b0_deb = '0' and count = 1_000_000) then
				if (state_id < 3) then
					state_id <= state_id + 1;
				else
					state_id <= 0;
				end if;
			end if;
			
			-- In state_id = 0, store A (4 bits)
			if (state_id = 0) then
				inA0 <= A0; inA1 <= A1; inA2 <= A2; inA3 <= A3;
			-- In state_id = 1, store B (4 bits) and ~B (4 bits)
			elsif (state_id = 1) then
				inB0 <= A0; inB1 <= A1; inB2 <= A2; inB3 <= A3;
				inNB0 <= NOT A0; inNB1 <= NOT A1; inNB2 <= NOT A2; inNB3 <= NOT A3;
            -- In state_id = 2, store the operation code
			else
				inOp0 <= A0; inOp1 <= A1; inOp2 <= A2;
			end if;
		end if;
	end process;
	
	-- State vector storage process
	process(state_id)
	begin
	    -- Set only first bit as 1 if state_id = 0
		if (state_id = 0) then
			state(0) <= '1';
			state(1) <= '0';
			state(2) <= '0';
		-- Set only second bit as 1  if state_id = 1
		elsif (state_id = 1) then
			state(0) <= '0';
			state(1) <= '1';
			state(2) <= '0';
		-- Set only third bit as 1 if state_id = 2
		elsif (state_id = 2) then
			state(0) <= '0';
			state(1) <= '0';
			state(2) <= '1';
		-- Set all bits as 1 if state_id = 3
		elsif (state_id = 3) then
			state(0) <= '1';
			state(1) <= '1';
			state(2) <= '1';
		-- Set all bits as 0 if none of above
		else
			state(0) <= '0';
			state(1) <= '0';
			state(2) <= '0';
		end if;
	end process;
	
	-- Operation selection and calculus process
	process(state_id, inA0, inA1, inA2, inA3, inOp0, inOp1, inOp2, inB0, inB1, inB2, inB3, inNB0, inNB1, inNB2, inNB3)
	begin
	    -- Signals start as zero
		cout0 <= '0'; cout1 <= '0'; cout2 <= '0'; cout3 <= '0'; ovflw <= '0'; ngtv <= '0'; zero <= '0'; 
	
		-- Operation 0 | Code 000 | Equal
		if (state_id = 3 AND inOp2 = '0' AND inOp1 = '0' AND inOp0 = '0') then
		    -- Turn on LED0 if all bits are equal
			if ((inA0 = inB0) AND (inA1 = inB1) AND (inA2 = inB2) AND (inA3 = inB3)) then
				outS0 <= '1';
            -- Turn off LED0 and turn on zero flag if not equal
			else
				outS0 <= '0';
				zero <= '1';
			end if;
			
			outS1 <= '0';
			outS2 <= '0';
			outS3 <= '0';
			
		-- Operation 1 | Code 001 | Greater
		elsif (state_id = 3 AND inOp2 = '0' AND inOp1 = '0' AND inOp0 = '1') then
		    -- Verfies bits one by one to compare and turn on LED0 if greater
			if (inA3 > inB3) then
				outS0 <= '1';
			elsif ((inA3 = inB3) AND (inA2 > inB2)) then
				outS0 <= '1';
			elsif ((inA3 = inB3) AND (inA2 = inB2) AND (inA1 > inB1)) then
				outS0 <= '1';
			elsif ((inA3 = inB3) AND (inA2 = inB2) AND (inA1 = inB1) AND (inA0 > inB0)) then
				outS0 <= '1';
            -- Turn off LED0 and turn on zero flag if equal or smaller
			else
				outS0 <= '0';
				zero <= '1';
			end if;
			
			outS1 <= '0';
			outS2 <= '0';
			outS3 <= '0';
			
		-- Operation 2 | Code 010 | Smaller
		elsif (state_id = 3 AND inOp2 = '0' AND inOp1 = '1' AND inOp0 = '0') then
			if (inA3 > inB3) then
				outS0 <= '0';
				zero <= '1';
			elsif ((inA3 = inB3) AND (inA2 > inB2)) then
				outS0 <= '0';
				zero <= '1';
			elsif ((inA3 = inB3) AND (inA2 = inB2) AND (inA1 > inB1)) then
				outS0 <= '0';
				zero <= '1';
			elsif ((inA3 = inB3) AND (inA2 = inB2) AND (inA1 = inB1) AND (inA0 > inB0)) then
				outS0 <= '0';
				zero <= '1';
			elsif ((inA3 = inB3) AND (inA2 = inB2) AND (inA1 = inB1) AND (inA0 = inB0)) then
				outS0 <= '0';
				zero <= '1';
			else
				outS0 <= '1';
			end if;
			
			outS1 <= '0';
			outS2 <= '0';
			outS3 <= '0';
			
		-- Operação 3 : AND
		elsif (state_id = 3 AND inOp2 = '0' AND inOp1 = '1' AND inOp0 = '1') then
			outS0 <= inA0 AND inB0;
			outS1 <= inA1 AND inB1;
			outS2 <= inA2 AND inB2;
			outS3 <= inA3 AND inB3;
			
			if (outS0 = '0' AND outS1 = '0' AND outS2 = '0' AND outS3 = '0') then
				zero <= '1';
			end if;
			
			if (outS3 = '1') then
				ngtv <= '1';
			end if;
			
		-- Operação 4 : OR
		elsif (state_id = 3 AND inOp2 = '1' AND inOp1 = '0' AND inOp0 = '0') then
			outS0 <= inA0 OR inB0;
			outS1 <= inA1 OR inB1;
			outS2 <= inA2 OR inB2;
			outS3 <= inA3 OR inB3;
			
			if (outS0 = '0' AND outS1 = '0' AND outS2 = '0' AND outS3 = '0') then
				zero <= '1';
			end if;
			
			if (outS3 = '1') then
				ngtv <= '1';
			end if;
			
		-- Operação 5 : SOMA
		elsif (state_id = 3 AND inOp2 = '1' AND inOp1 = '0' AND inOp0 = '1') then
			outS0 <= inA0 XOR inB0;
			cout0 <= (inA0 and inB0);
			
			outS1 <= ((inA1 XOR inB1) XOR (inA0 AND inB0));
			cout1 <= (inA1 and inB1) OR ((inA1 XOR inB1) AND cout0);
			
			outS2 <= ((inA2 XOR inB2) XOR ((inA1 AND inB1) OR ((inA1 XOR inB1) AND (inA0 AND inB0))));
			cout2 <= (inA2 and inB2) OR ((inA2 XOR inB2) AND cout1);
			
			outS3 <= ((inA3 XOR inB3) XOR ((inA2 AND inB2) OR ((inA2 XOR inB2) AND (inA1 AND inB1)) OR ((inA2 XOR inB2) AND (inA1 XOR inB1) AND (inA0 AND inB0))));
			cout3 <= (inA3 and inB3) OR ((inA3 XOR inB3) AND cout2);
			
			if (outS0 = '0' AND outS1 = '0' AND outS2 = '0' AND outS3 = '0') then
				zero <= '1';
			end if;
			
			ovflw <= cout2 XOR cout3;
			
			if (outS3 = '1' AND ovflw = '0') then
				ngtv <= '1';
			end if;
		
		-- Operação 6 : SUBTRAÇÃO
		elsif (state_id = 3 AND inOp2 = '1' AND inOp1 = '1' AND inOp0 = '0') then
			outS0 <= (inA0 XOR inNB0) XOR '1';
			cout0 <= (inA0 and inNB0) OR ((inA0 XOR inNB0) AND '1');
			
			outS1 <= (inA1 XOR inNB1) XOR cout0;
			cout1 <= (inA1 and inNB1) OR ((inA1 XOR inNB1) AND cout0);
			
			outS2 <= (inA2 XOR inNB2) XOR cout1;
			cout2 <= (inA2 and inNB2) OR ((inA2 XOR inNB2) AND cout1);
			
			outS3 <= (inA3 XOR inNB3) XOR cout2;
			cout3 <= (inA3 and inNB3) OR ((inA3 XOR inNB3) AND cout2);
			
			if (outS0 = '0' AND outS1 = '0' AND outS2 = '0' AND outS3 = '0') then
				zero <= '1';
			end if;
			
			ovflw <= cout2 XOR cout3;
			
			if (outS3 = '1' AND ovflw = '0') then
				ngtv <= '1';
			end if;
			
		-- Operação 7 : SHIFT
		elsif (state_id = 3 AND inOp2 = '1' AND inOp1 = '1' AND inOp0 = '1') then
			-- 0000 : zero bits para esquerda
			if (inB3 = '0' AND inB2 = '0' AND inB1 = '0' AND inB0 = '0') then
				outS0 <= inA0; outS1 <= inA1; outS2 <= inA2; outS3 <= inA3;
			
			-- 0001 : um bit para a esquerda
			elsif (inB3 = '0' AND inB2 = '0' AND inB1 = '0' AND inB0 = '1') then
				outS0 <= '0'; outS1 <= inA0; outS2 <= inA1; outS3 <= inA2;
				if (inA3 = '1') then
					ovflw <= '1';
				end if;
				
			-- 0011 : dois bits para a esquerda
			elsif (inB3 = '0' AND inB2 = '0' AND inB1 = '1' AND inB0 = '1') then
				outS0 <= '0'; outS1 <= '0'; outS2 <= inA0; outS3 <= inA1;
				if (inA3 = '1' OR inA2 = '1') then
					ovflw <= '1';
				end if;
			
			-- 0111 : tres bits para a esquerda
			elsif (inB3 = '0' AND inB2 = '1' AND inB1 = '1' AND inB0 = '1') then
				outS0 <= '0'; outS1 <= '0'; outS2 <= '0'; outS3 <= inA0;
				if (inA3 = '1' OR inA2 = '1' OR inA3 = '1') then
					ovflw <= '1';
				end if;
			
			-- 1000 : zero bits para direita
			elsif (inB3 = '1' AND inB2 = '0' AND inB1 = '0' AND inB0 = '0') then
				outS0 <= inA0; outS1 <= inA1; outS2 <= inA2; outS3 <= inA3;
			
			-- 1001 : um bit para a direita
			elsif (inB3 = '1' AND inB2 = '0' AND inB1 = '0' AND inB0 = '1') then
				outS0 <= inA1; outS1 <= inA2; outS2 <= inA3; outS3 <= '0';
				
			-- 1011 : dois bits para a direita
			elsif (inB3 = '1' AND inB2 = '0' AND inB1 = '1' AND inB0 = '1') then
				outS0 <= inA2; outS1 <= inA3; outS2 <= '0'; outS3 <= '0';
			
			-- 1111 : tres bits para a direita
			elsif (inB3 = '1' AND inB2 = '1' AND inB1 = '1' AND inB0 = '1') then
				outS0 <= inA3; outS1 <= '0'; outS2 <= '0'; outS3 <= '0';
				
			else
				outS0 <= '0'; outS1 <= '0'; outS2 <= '0'; outS3 <= '0';
			end if;
			
			if (outS0 = '0' AND outS1 = '0' AND outS2 = '0' AND outS3 = '0') then
				zero <= '1';
			end if;
			
			if (outS3 = '1') then
				ngtv <= '1';
			end if;
		else
			outS0 <= '0'; outS1 <= '0'; outS2 <= '0'; outS3 <= '0';
		end if;
	end process;
	
	A0_out <= A0 when (state_id < 3) else outS0;
	A1_out <= A1 when (state_id < 3) else outS1;
	A2_out <= A2 when (state_id < 3) else outS2;
	A3_out <= A3 when (state_id < 3) else outS3;
	
	S0_out <= state(0) when (state_id < 3) else zero;
	S1_out <= state(1) when (state_id < 3) else ngtv;
	S2_out <= state(2) when (state_id < 3) else cout3;
	S3_out <= b0_deb when (state_id < 3) else ovflw;

end Behavioral;