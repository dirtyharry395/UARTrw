----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Kasper Grue Understrup
-- 
-- Create Date:    22:31:04 09/19/2018 
-- Design Name: 
-- Module Name:    uartrw - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uartrw is
port( led: out std_logic_vector(7 downto 0);
      clk: in std_logic;
		tx: out std_logic;
		rx : in std_logic
		--sw: in std_logic
		--sw1: in std_logic
		);
end uartrw;

architecture Behavioral of uartrw is

--WRITING
signal transmission: std_logic_vector(6 downto 0) := "1111111";
signal send: std_logic := '1';
signal counter2: std_logic_vector(3 downto 0):= (others => '0');

--READING
signal readByte: std_logic_vector(7 downto 0) := "00000000";
signal readcounter: std_logic_vector(3 downto 0):= "1111";
signal sendsignal: std_logic := '0';
signal slowCounter: std_logic := '0';
signal writeSignal: std_logic := '0';

--Logic
signal startWrite: std_logic := '0';
type intArray is array (0 to 255) of std_logic_vector(6 downto 0);
signal intA: intArray;
signal transmissioncounter: std_logic_vector(7 downto 0):= "00000000";
signal displaycounter: std_logic_vector(7 downto 0):= "00000000";
signal play: std_logic := '0';

--Writeclock
signal counter: std_logic_vector(8 downto 0):= (others => '0');
signal baudcounter: std_logic_vector(8 downto 0) := "110110011";

--ReadClock
signal slowCounter1: std_logic := '0';
signal clocksync: std_logic_vector(9 downto 0) := "0000000011";
signal counter3: std_logic_vector(8 downto 0):= "010000000";

--Sync Clock
signal syncClock: std_logic_vector(8 downto 0):= (others => '0');
signal clockstate: std_logic:= '0';
signal testValue: std_logic_vector(7 downto 0):= "00000000";

--Write Clock
begin
	process(clk)
	begin
			if (clk = '1' and clk'event) then
				counter <= std_logic_vector( unsigned(counter) +1 );
				if (counter >= baudcounter) then
					slowCounter <= '1';
					counter <= "000000000";
				else 
					slowCounter <= '0';
				end if;
			end if;
	end process;

--Read Clock
	process(clk)
	begin
		if (clk = '1' and clk'event) then
			if(rx = '0' and clocksync = "0000001000" and readcounter = "1111") then
				slowCounter1 <= '0';
				counter3 <= "010000000";
				clocksync <= "0000000000";
			elsif (counter3 >= baudcounter) then
				slowCounter1 <= '1';
				counter3 <= "000000000";
				if clocksync = "0000001000" then
					clocksync <= "0000001000";
				else
					clocksync <= std_logic_vector( unsigned(clocksync) +1 );
				end if;
			else
				slowCounter1 <= '0';
				counter3 <= std_logic_vector( unsigned(counter3) +1 );
			end if;

		end if;
	end process;

--Clock Syncronization
	process(clk)
	begin
			if (clk = '1' and clk'event) then
				syncClock <= std_logic_vector( unsigned(syncClock) +1 );
				if (syncClock = "111111111") then
					syncClock <= "000000000";
					clockstate <= '0';
				end if;
				if (rx='0' and clockstate = '0') then
					clockstate <= '1';
					syncClock <= "000000000";
				elsif (rx='1' and clockstate = '1' and syncClock(8 downto 4) = "11011") then
					clockstate <= '0';
					baudcounter <= std_logic_vector( unsigned(syncClock) -1 );
					syncClock <= "000000000";
				end if;
			end if;
	end process;
	
--

--Logic
	process (clk)
	begin
		if (clk = '1' and clk'event) then
			if (sendsignal = '0' and play = '0') then
				startWrite <= '0';
			else
				if (displaycounter = transmissioncounter) then
					play <= '0';
				elsif (play = '1') then
					if (writeSignal = '0') then
						transmission <= intA(to_integer(unsigned(displaycounter)-1));
						displaycounter <= std_logic_vector( unsigned(displaycounter) +1 );
						startWrite <= '1';
					end if;
				elsif (intA(to_integer(unsigned(transmissioncounter) -1)) = "0100011" and intA(to_integer(unsigned(transmissioncounter) -2)) = "0100011") then
					play <= '1';
					testValue <= std_logic_vector( unsigned(transmissioncounter) - unsigned(displaycounter));
				else
					transmission <= intA(to_integer(unsigned(transmissioncounter) -1)); --readByte(6 downto 0);
					startWrite <= '1';
				end if;
			end if;
		end if;
	end process;

--READING
	process (clk,rx)
	begin
			if (clk = '1' and clk'event and slowCounter1 = '1') then
				if (rx = '0' and readcounter = "1111") then
					if (readByte(6 downto 0) = "0100010") then
						transmissioncounter <= std_logic_vector( unsigned(transmissioncounter) -2); 
					end if;
					readcounter <= "0000";
					sendsignal <= '0';
					readByte <= "00000000";
				elsif (readcounter = "0000" or readcounter = "0001" or readcounter = "0010" or readcounter = "0011" or readcounter = "0100" or readcounter = "0101" or readcounter = "0110"  or readcounter = "0111") then
					readByte(6 downto 0) <= readByte (7 downto 1);
					readByte(7) <= rx;
					readcounter <= std_logic_vector( unsigned(readcounter) +1 );
					sendsignal <= '0';
				elsif (readcounter = "1000") then
					readcounter <= std_logic_vector( unsigned(readcounter) +1 );
					intA(to_integer(unsigned(transmissioncounter))) <= readByte(6 downto 0);
					transmissioncounter <= std_logic_vector( unsigned(transmissioncounter) +1 );
					sendsignal <= '1';
				else
					readcounter <= "1111";
					sendsignal <= '0';
				end if;
			end if;
	end process;

--Writing
	process (clk)
	begin
			if (clk = '1' and clk'event) then
				if (startWrite = '1') then
					writeSignal <= '1';
				end if;
		      if (slowCounter = '1' and writeSignal = '1') then
					if (counter2 = "1111") then
						send <= '0';
						counter2 <= "0000";
					elsif (counter2 = "1000") then
						counter2 <= std_logic_vector( unsigned(counter2) +1 );
						send <= '1';
					elsif (counter2 = "0---") then
						case counter2(2 downto 0) is
							when "000" => send <= transmission(0);
							when "001" => send <= transmission(1);
							when "010" => send <= transmission(2);
							when "011" => send <= transmission(3);
							when "100" => send <= transmission(4);
							when "101" => send <= transmission(5);
							when "110" => send <= transmission(6);
						when others => send <= '0';
						end case;
						counter2 <= std_logic_vector( unsigned(counter2) +1 );
					else
						counter2 <= "1111";
						writeSignal <= '0';
						send <= '1';
					end if;
				end if;
			end if;
   end process;
	LED <= testValue;
	tx <= send;
end Behavioral;