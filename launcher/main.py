# other parts of this application
import AppInfo
import FirstTime
import Upload
import RedirectHandler
import ReportsReader
import SamplerConfig
import ServerMessage
import Spawn

# GTK+ libraries
import gtk

# standard Python libraries
import email
import os
import signal
import sys
import urllib2


########################################################################


def main():
    application = AppInfo.AppInfo()
    gconfig = SamplerConfig.SamplerConfig(application)

    # present first time dialog if we haven't already asked
    if not gconfig['asked']:
        firstTime = FirstTime.FirstTime(application, gconfig)
        response = firstTime.run()
        firstTime.hide()
        if response != gtk.RESPONSE_OK:
            sys.exit(1)

        # wait for dialog to go away before launching main app
        while gtk.events_pending():
            gtk.main_iteration()

        gconfig['enabled'] = firstTime.enabled()
        gconfig['asked'] = 1

    # should we really sample?
    enabled = gconfig['enabled']
    sparsity = gconfig['sparsity']
    enabled &= (sparsity > 0)
    reportingUrl = gconfig['reporting-url']
    enabled &= (reportingUrl != None)

    if enabled:
        # run the real application
        process = Spawn.Spawn(sparsity, application)
        old_sigint = signal.signal(signal.SIGINT, lambda signum, frame: process.kill(signum))

        # collect its reports and exit status
        reports = ReportsReader.ReportsReader(process.reportsFile)
        [exitStatus, exitSignal] = process.wait()
        signal.signal(signal.SIGINT, old_sigint)

        # compress reports in preparation for upload
        compressLevel = gconfig['compression-level']
        if compressLevel < 1 or compressLevel > 9:
            compressLevel = 9
        upload = Upload.Upload(reports, compressLevel)

        # easy-access headers with info about this specific run
        synopsis = {'Version' : '0.1',
                    'Program-Name' : application.name,
                    'Random-Seed' : process.seed,
                    'Sparsity' : str(sparsity),
                    'Exit-Status' : str(exitStatus),
                    'Exit-Signal' : str(exitSignal)}

        # easy-access headers with info about the application
        for option in application.options('synopsis'):
            assert option not in synopsis
            synopsis[option] = application.get('synopsis', option)

        # finish assembling the upload request
        headers = {'Content-type' : 'multipart/form-data; boundary="' + upload.boundary + '"'}
        for header in synopsis:
            headers['Sampler-' + header] = synopsis[header]

        # install our special redirect hander
        redirect = RedirectHandler.RedirectHandler()
        urllib2.install_opener(urllib2.build_opener(redirect))

        # post the upload and read server's response
        request = urllib2.Request(reportingUrl, str(upload), headers)
        reply = urllib2.urlopen(request)

        # server may have requested a permanent URL change
        if redirect.permanent:
            gconfig['reporting-url'] = redirect.permanent

        # server may have requested a sparsity change
        message = email.message_from_file(reply)
        if 'Sparsity' in message:
            gconfig['sparsity'] = message['Sparsity']

        # server may have posted a message for the user
        payload = message.get_payload()
        if payload:
            serverMessage = ServerMessage.ServerMessage(application, reply, message)
            serverMessage.run()
            serverMessage.hide()

        # done!
        sys.exit(exitSignal or exitStatus)

    else:
        # force sampling off
        if 'SAMPLER_SPARSITY' in os.environ:
            del os.environ['SAMPLER_SPARSITY']
        os.execv(application.executable, sys.argv)
