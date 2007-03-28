package DBD::Gofer::Transport::Base;

#   $Id$
#
#   Copyright (c) 2007, Tim Bunce, Ireland
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

use base qw(DBI::Gofer::Transport::Base);

our $VERSION = sprintf("0.%06d", q$Revision$ =~ /(\d+)/o);

__PACKAGE__->mk_accessors(qw(
    trace
    go_dsn
    go_url
    go_timeout
));


sub _init_trace { $ENV{DBD_GOFER_TRACE} || 0 }

sub transmit_request {
    my ($self, $request) = @_;

    my $to = $self->go_timeout;
    local $SIG{ALRM} = sub { die "TIMEOUT\n" } if $to;

    my $info = eval {
        alarm($to) if $to;
        $self->transmit_request_by_transport($request);
    };
    alarm(0) if $to;

    if ($@) {
        return $self->transport_timedout("transmit_request", $to)
            if $@ eq "TIMEOUT\n";
        return DBI::Gofer::Response->new({ err => 1, errstr => $@ });
    }

    return undef;
}


sub receive_response {
    my $self = shift;

    my $to = $self->go_timeout;
    local $SIG{ALRM} = sub { die "TIMEOUT\n" } if $to;

    my $response = eval {
        alarm($to) if $to;
        $self->receive_response_by_transport();
    };
    alarm(0) if $to;

    if ($@) {
        return $self->transport_timedout("receive_response", $to)
            if $@ eq "TIMEOUT\n";
        return DBI::Gofer::Response->new({ err => 1, errstr => $@ });
    }

    return $response;
}


sub transport_timedout {
    my ($self, $method, $timeout) = @_;
    $timeout ||= $self->go_timeout;
    return DBI::Gofer::Response->new({ err => 1, errstr => "DBD::Gofer $method timed-out after $timeout seconds" });
}


1;

=head1 NAME

DBD::Gofer::Transport::Base - base class for DBD::Gofer client transports


=head1 AUTHOR AND COPYRIGHT

The DBD::Gofer, DBD::Gofer::* and DBI::Gofer::* modules are
Copyright (c) 2007 Tim Bunce. Ireland.  All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

L<DBD::Gofer>

and some example transports:

L<DBD::Gofer::Transport::stream>

L<DBD::Gofer::Transport::http>

L<DBI::Gofer::Transport::mod_perl>

=cut
