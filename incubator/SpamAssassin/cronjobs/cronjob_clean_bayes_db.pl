#!/usr/bin/perl
# i-MSCP SpamAssassin plugin
# Copyright (C) 2013-2015 Sascha Bay <info@space2place.de>
# Copyright (C) 2013-2015 Rene Schuster <mail@reneschuster.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

use lib '{IMSCP_PERLLIB_PATH}';
use iMSCP::Debug;
use iMSCP::Bootstrapper;
use iMSCP::Database;
use iMSCP::EventManager;
use JSON;

sub getData
{
	my $row = iMSCP::Database->factory()->doQuery(
		'plugin_name',
		'SELECT plugin_name, plugin_info, plugin_config, plugin_config_prev FROM plugin WHERE plugin_name = ?',
		'SpamAssassin'
	);
	ref $row eq 'HASH' or die($row);
	$row->{'SpamAssassin'} or die('SpamAssassin plugin data not found in database');

	{
		action => 'cron',
		config => decode_json($row->{'SpamAssassin'}->{'plugin_config'}),
		config_prev => decode_json($row->{'SpamAssassin'}->{'plugin_config_prev'}),
		eventManager => iMSCP::EventManager->getInstance(),
		info => decode_json($row->{'SpamAssassin'}->{'plugin_info'})
	};
}

newDebug('spamassassin-plugin-cronjob.log');
iMSCP::Bootstrapper->getInstance()->boot({ norequirements => 'yes', config_readonly => 'yes', nolock => 'yes' });

my $pluginFile = "$main::imscpConfig{'PLUGINS_DIR'}/SpamAssassin/backend/SpamAssassin.pm";
require $pluginFile;

my $pluginClass = "Plugin::SpamAssassin";
$pluginClass->getInstance(getData())->cleanBayesDb() == 0 or die(
	getMessageByType('error', { amount => 1, remove => 1 }) || 'Unknown error'
);
