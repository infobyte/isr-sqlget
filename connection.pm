package connection;
use Data::Dump qw(dump);

use LWP::UserAgent;
use HTTP::Cookies;
use Convert::EastAsianWidth;
		
my @agenthost;

#Constructor y destructor de clase
sub new {
    my $classname = shift;
    my $class = {@_};

    if ($class->{ruseragent}){
	open(FZ,$class->{ruseragentfile}) or print "Error open file: ($class->{ruseragentfile}) $@\n";
	my @tmparray=<FZ>;
	close(FZ);
	$class->{ruseragentarray}=\@tmparray;
	$class->{ruseragentarrayc}=$#tmparray;
	
    }
    
    if ($class->{rproxy}){
	open(FZ,$class->{rproxyfile}) or print "Error open file: ($class->{rproxyfile}) $@\n";
	my @tmparray=<FZ>;
	close(FZ);
	$class->{rproxyarray}=\@tmparray;
	$class->{rproxyarrayc}=$#tmparray;
    }

    
    bless $class, $classname;
    return $class;
}

sub DESTROY {
}

sub getpage {
    my ($class,$url,$datos,$method ) =@_;
    $method ||=$class->{method};
    $datos ||=$class->{inj};
    $url ||=$class->{site}.$class->{script};
    
#    exit;
    #bypass space
    if ($class->{'space'} == 1){
	$datos=~ s/ /\t/gi;
    }elsif($class->{'space'} ==2){
	$datos=~ s/ /\/\*\*\//gi;
    }
    
    #bypass random uppercase
    if ($class->{rnd_uppercase}){
	my @groups = split(/\&/,$datos);
	my $toencode="";
	my $alldata="";
	foreach(@groups)
	{
	    /^([\w\s]+)=([\S\w\s\W]+)/;
	    $toencode .= '&' if ($toencode);
	    my $encdatos=$2;
	    $toencode .=$1."=";
	    map {
		if (int(rand(2))==1 ){
		    $toencode.=lc($_);
		}else{
    		    $toencode.=uc($_);
		}
    	    } split(//,$encdatos);
	    
	}
	$datos=$toencode;
    }
	    
    #bypass using full_width
    if ($class->{full_width}==1) {
	my @groups = split(/\&/,$datos);
	my $toencode="";
	my $alldata="";
	foreach(@groups)
	{
	    /^([\w\s]+)=([\S\w\s\W]+)/;
	    $toencode .= '&' if ($toencode);
	    my $encdatos=to_fullwidth($2);
	    $toencode .=$1."=";
	    map { $toencode.="%"; $toencode.=sprintf("%x",ord($_)); } split(//,$encdatos);
	}
	$datos=$toencode;
    }elsif($class->{convertall_hex}){
	my @groups = split(/\&/,$datos);
	my $toencode="";
	my $alldata="";
	foreach(@groups)
	{
	    /^([\w\s]+)=([\S\w\s\W]+)/;
	    $toencode .= '&' if ($toencode);
	    my $encdatos=$2;
	    $toencode .=$1."=";
	    map { $toencode.="%"; $toencode.=sprintf("%x",ord($_)); } split(//,$encdatos);
	}
	$datos=$toencode;
    }    
    #bypass mod_security
    $datos =chr(00).$datos if ($class->{mod_security}==1);
    
    print "\n$url,$datos,$method\n";
#    exit;
    if ($class->{delay}){
	print "[**] - Wait $class->{delay} minutes before connection\n";
	sleep $class->{delay};
    }elsif($class->{rdelay}){
	my $rdelay = int(rand($class->{rdelay}));
	print "[**] - Random Wait $rdelay minutes before connection\n";
	sleep $rdelay;
    }
    
    #exit;
    my $ua;
    if ($class->{apache_espace_rnd}){
	my $cant = 1;
	$cant = int(rand($class->{apache_espace_rmaxn})) if ($class->{apache_espace_rmaxn});
	$cant = int(rand($class->{apache_espace_rmaxn})) if ($cant ==0);
	print "DEBUG: apache_espace_rmaxn = $cant\n" if ($class->{debug});
	my $space_t= rand_apache($cant);
	print "DEBUG: apache_espace = ".dump($space_t)."\n" if ($class->{debug});
	$ua = LWP::UserAgent->new(space_type=>$space_t);
    }elsif($class->{apache_espace}){
	$ua = LWP::UserAgent->new(space_type=>$class->{apache_espace});
    }else{
	$ua  = LWP::UserAgent->new(space_type=>' , ');
    }

    #random useragent
    if ($class->{ruseragent}){
	my $ranagent=cut($class->{ruseragentarray}[int(rand($class->{ruseragentarrayc}))]);
	print "DEBUG: Using random agent: $ranagent\n" if ($class->{debug});
	$ua->agent($ranagent);
    }	
    else
    {
	$ua->agent($class->{uagent}) if ($class->{uagent});
    }

    #random proxys
    if ($class->{rproxy}){
        print "Using random agent: $ranproxy\n" if ($class->{debug});
    	my $ranproxy=cut($class->{ruseragentarray}[int(rand($class->{ruseragentarrayc}))]);
	$ua->proxy(['http','https'] => $ranproxy);
    }	
    else
    {
	$ua->proxy(['http','https'] => $class->{proxy_host}) if ($class->{proxy_host});    
    }

    my $jar = HTTP::Cookies->new();
    $url .= "?$datos" if ($class->{param} == 2);
    my $req = HTTP::Request->new($method => $url);
#    print "B".dump($req)."\n";
    if ($class->{cookie}){
	foreach my $item (@{$class->{cookies}}){
	    $jar->set_cookie(
	    		$item->{version},
                        $item->{key},
                        $item->{val},
                        $item->{path},
                        $item->{domain},
                        $item->{port},
                        $item->{path_spec},
                        $item->{secure},
                        $item->{maxage},
                        $item->{discard},
                        $item->{rest} );
	}			
	$ua->cookie_jar($jar);
	$jar->add_cookie_header($req);	
	
    }

    $req->content_type('application/x-www-form-urlencoded');
    $req->content($datos) if ($class->{param} == 1);
    my $res = $ua->request($req);
    $class->{response} = $res->as_string;
    $class->{code} = $res->code;
    return $class->{response};
}
sub rand_apache{
    my ($cant) = @_;
    my @rand=("\x0b","\x0c","\x0d"); #0x0b, 0x0c, 0x0d
#    my @rand=("a","b","c","d"); #0x0b, 0x0c, 0x0d
    my $n=$#rand;
    my $ini;
    my $fin;
    for(my $i=1;$i<=$cant;$i++){
        $ini .= $rand[int(rand($n))];
        $fin .= $rand[int(rand($n))];
    }
    return "$ini,$fin";
}
						    
sub cut{
    my ($val) = @_;
    chop($val);
    return $val;
}
	    

1;
