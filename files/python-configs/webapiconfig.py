import socorro.lib.ConfigurationManager as cm
import datetime

from config.commonconfig import databaseHost
from config.commonconfig import databasePort
from config.commonconfig import databaseName
from config.commonconfig import databaseUserName
from config.commonconfig import databasePassword

#---------------------------------------------------------------------------
# HBase storage system
from config.commonconfig import hbaseStorageClass

from config.commonconfig import hbaseHost
from config.commonconfig import hbasePort
from config.commonconfig import hbaseTimeout

from config.commonconfig import secondaryHbaseHost
from config.commonconfig import secondaryHbasePort
from config.commonconfig import secondaryHbaseTimeout

from config.smtpconfig import smtpHostname
from config.smtpconfig import smtpPort
from config.smtpconfig import smtpUsername
from config.smtpconfig import smtpPassword
from config.smtpconfig import fromEmailAddress
from config.smtpconfig import unsubscribeBaseUrl

wsgiInstallation = cm.Option()
wsgiInstallation.doc = 'True or False, this app is installed under WSGI'
wsgiInstallation.default = True

import socorro.services.topCrashBySignatureTrends as tcbst
import socorro.services.signatureHistory as sighist
import socorro.services.aduByDay as adubd
import socorro.services.aduByDayDetails as adudetails
import socorro.services.getCrash as crash
import socorro.services.emailCampaign as emailcampaign
import socorro.services.emailCampaignCreate as emailcreate
import socorro.services.emailCampaigns as emaillist
import socorro.services.emailCampaignVolume as emailvolume
import socorro.services.emailSubscription as emailsub
import socorro.services.emailSender as emailsend

servicesList = cm.Option()
servicesList.doc = 'a python list of classes to offer as services'
servicesList.default = [tcbst.TopCrashBySignatureTrends, sighist.SignatureHistory, adubd.AduByDay, adubd.AduByDay200912, adudetails.AduByDayDetails, crash.GetCrash, emailcampaign.EmailCampaign, emailcreate.EmailCampaignCreate, emaillist.EmailCampaigns, emailvolume.EmailCampaignVolume, emailsub.EmailSubscription, emailsend.EmailSender]

crashBaseUrl = cm.Option()
crashBaseUrl.doc = 'The base url for linking to crash-stats. This will be used in email templates'
crashBaseUrl.default = "http://crash-stats/report/index/%s"

#---------------------------------------------------------------------------
# Logging
syslogHost = cm.Option()
syslogHost.doc = 'syslog hostname'
syslogHost.default = 'localhost'

syslogPort = cm.Option()
syslogPort.doc = 'syslog port'
syslogPort.default = 514

syslogFacilityString = cm.Option()
syslogFacilityString.doc = 'syslog facility string ("user", "local0", etc)'
syslogFacilityString.default = 'user'

syslogLineFormatString = cm.Option()
syslogLineFormatString.doc = 'python logging system format for syslog entries'
syslogLineFormatString.default = 'Socorro Web Services (pid %(process)d): %(asctime)s %(levelname)s - %(threadName)s - %(message)s'

syslogErrorLoggingLevel = cm.Option()
syslogErrorLoggingLevel.doc = 'logging level for the log file (10 - DEBUG, 20 - INFO, 30 - WARNING, 40 - ERROR, 50 - CRITICAL)'
syslogErrorLoggingLevel.default = 10
