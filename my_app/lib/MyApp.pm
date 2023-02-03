package MyApp;
use Mojo::Base 'Mojolicious';
use DBI;

sub startup {
	my $self = shift;

	my $config = $self->plugin('Config');

	$self->secrets($config->{secrets});

	my $db_name = $config->{db_db};
	my ($user, $pass) = ($config->{db_user}, $config->{db_pass});
	my $dsn = "dbi:mysql:database=$db_name";
	my $dbh = DBI->connect($dsn, $user, $pass);

	$self->helper( db =>
		sub {
			return $dbh;
		}
	);

	my $validator = Mojolicious::Validator->new;

	$self->helper( validator =>
		sub {
			return $validator;
		}
	);

	my $r = $self->routes;

	$r->get('/')->to('example#welcome');
	$r->post('/get_log')->to('example#get_log');
}

1;
