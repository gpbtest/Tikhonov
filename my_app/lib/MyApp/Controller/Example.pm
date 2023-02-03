package MyApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

use constant {MAX_COUNT => 100};

sub welcome {
  my $self = shift;

  $self->render();
}

sub get_log {
	my $self = shift;

	my $v = $self->validator->validation;

	$v->input({search_q => $self->param('search_q')});
	# простенькая валидация, без Email::Valid
	$v->required('search_q')->like(qr/^[a-z0-9A-Z][A-Za-z0-9.]+[A-Za-z0-9]\@[A-Za-z0-9.-]+$/);
	if ($v->has_error) {
		return $self->render(json => {error => 'Input param error'});
	}

	my $search_q = $v->param('search_q');

	# знаю, обычно используют модель, но в данном случае обойдёмся.
	my $db = $self->db;

	my $h_count = $db->selectrow_hashref("
		SELECT COUNT(*) as count
		FROM
			(SELECT m.int_id, m.created, m.str
			FROM test.message m
			WHERE m.int_id in (SELECT int_id FROM test.log WHERE address = ?)
			UNION
			SELECT l.int_id, l.created, l.str FROM test.log l WHERE l.address = ?) a",
		{},
		$search_q, $search_q
	);

	my $result = {};

	if (defined($h_count->{count}) && $h_count->{count} > MAX_COUNT) {
		$result->{line_limit_exceeded} = 1;
	}

	my $a_data = $db->selectall_arrayref("
		SELECT a.created, a.str
		FROM
			(SELECT m.int_id, m.created, m.str
			FROM test.message m
			WHERE m.int_id in (SELECT int_id FROM test.log WHERE address = ?)
			UNION
			SELECT l.int_id, l.created, l.str FROM test.log l WHERE l.address = ?) a
		ORDER by a.int_id, a.created
		LIMIT 100",
		{},
		$search_q, $search_q
	);

	if (defined($a_data)) {
		$result->{data} = $a_data;
	}

	$result->{result} = 'ok';

	$self->render(json => $result);
}

1;
