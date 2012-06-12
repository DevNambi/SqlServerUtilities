-- SQL and OS Version information for current instance
SELECT [Poll Time]=getdate(), [Server Name]=@@ServerName, @@VERSION AS [SQL Server and OS Version Info];

-- SQL Server 2008 RTM is considered an "unsupported service pack" as of April 13, 2010
-- SQL Server 2008 RTM Builds   SQL Server 2008 SP1 Builds     SQL Server 2008 SP2 Builds		SQL Server 2008 SP3 Builds
-- Build       Description      Build       Description		   Build     Description			Build		Description
-- 1600        Gold RTM
-- 1763        RTM CU1
-- 1779        RTM CU2
-- 1787        RTM CU3    -->	2531		SP1 RTM
-- 1798        RTM CU4    -->	2710        SP1 CU1
-- 1806        RTM CU5    -->	2714        SP1 CU2 
-- 1812		   RTM CU6    -->	2723        SP1 CU3
-- 1818        RTM CU7    -->	2734        SP1 CU4
-- 1823        RTM CU8    -->	2746		SP1 CU5
-- 1828		   RTM CU9    -->	2757		SP1 CU6
-- 1835		   RTM CU10   -->	2766		SP1 CU7
-- RTM Branch Retired     -->	2775		SP1 CU8		-->  4000	   SP2 RTM
--								2789		SP1 CU9
--								2799		SP1 CU10	
--								2804		SP1 CU11	-->  4266      SP2 CU1		
--								2808		SP1 CU12	-->  4272	   SP2 CU2	
--								2816	    SP1 CU13    -->  4279      SP2 CU3	
--								2821		SP1 CU14	-->  4285	   SP2 CU4	-->				5500		SP3 RTM
--								2847		SP1 CU15	-->  4316	   SP2 CU5  
--								2850		SP1 CU16	-->  4321	   SP2 CU6	-->				5766		SP3 CU1	
--                              SP1 Branch Retired      -->  4323      SP2 CU7  -->             5768        SP3 CU2
--                                                           4326	   SP2 CU8  -->             5770		SP3 CU3
--														     4330	   SP2 CU9  -->				5775		SP3 CU4

-- The SQL Server 2008 builds that were released after SQL Server 2008 was released
-- http://support.microsoft.com/kb/956909

-- The SQL Server 2008 builds that were released after SQL Server 2008 Service Pack 1 was released
-- http://support.microsoft.com/kb/970365
--
-- The SQL Server 2008 builds that were released after SQL Server 2008 Service Pack 2 was released 
-- http://support.microsoft.com/kb/2402659	
--
-- The SQL Server 2008 builds that were released after SQL Server 2008 Service Pack 3 was released
-- http://support.microsoft.com/kb/2629969					   



-- SQL Server 2008 R2 Builds				SQL Server 2008 R2 SP1 Builds
-- Build			Description				Build		Description
-- 10.50.1092		August 2009 CTP2		
-- 10.50.1352		November 2009 CTP3
-- 10.50.1450		Release Candidate
-- 10.50.1600		RTM
-- 10.50.1702		RTM CU1
-- 10.50.1720		RTM CU2
-- 10.50.1734		RTM CU3
-- 10.50.1746		RTM CU4
-- 10.50.1753		RTM CU5
-- 10.50.1765		RTM CU6	 --->			10.50.2500	SP1 RTM
-- 10.50.1777		RTM CU7
-- 10.50.1797		RTM CU8	 --->			10.50.2769  SP1 CU1
-- 10.50.1804       RTM CU9  --->			10.50.2772  SP1 CU2
-- 10.50.1807		RTM CU10 --->           10.50.2789  SP1 CU3
-- 10.50.1809       RTM CU11 --->			10.50.2796  SP1 CU4 
-- 10.50.1810		RTM CU12 --->			10.50.2806	SP1 CU5
-- 10.50.1815		RTM CU13 --->           10.50.2811  SP1 CU6       

-- The SQL Server 2008 R2 builds that were released after SQL Server 2008 R2 was released
-- http://support.microsoft.com/kb/981356

-- The SQL Server 2008 R2 builds that were released after SQL Server 2008 R2 Service Pack 1 was released 
-- http://support.microsoft.com/kb/2567616

