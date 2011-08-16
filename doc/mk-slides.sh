#!/bin/sh
# cpan Pod::S5

perl -MTest::Pod -e'use Test::Simple tests=>1;pod_file_ok q(yapc_2011.pod);' && \
pod2s5 --theme rurban --creation "Riga Tue Aug 16, 2011" \
	--name "use types YAPC::EU 2011" \
	--where "Reini Urban" yapc_2011.pod
