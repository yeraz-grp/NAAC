#!/usr/bin/env python3

import questionary
import pynetbox
import urllib3

from colorama import Back

from misc.i18n import setup_translation, _
from misc.util import clean_screen, is_fqdn, is_ipv4
from misc.ui import Display
from misc.configuration import Configuration

netbox = None

def RaiseError(error):
    Display.box(_(error))
    quit();

def netboxConnect():
    netbox_url = Configuration.get("netbox.url")
    netbox_token = Configuration.get("netbox.token")
    
    if (not netbox_url):
        RaiseError("Network URL not set in configuration file.")

    if (not netbox_token):
        RaiseError("Network Token not set in configuration file.")

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    global netbox
    netbox = pynetbox.api(
        netbox_url,
        token=netbox_token
    )
    netbox.http_session.verify = False


def get_vmName():
    vm_name = ""
    fqdn = False
    while (not vm_name or not fqdn):
        if (vm_name.strip() != "" and not fqdn):
            Display.box(_("Please enter a machine name as an FQDN. Example: host.domain.tld"))
        vm_name = questionary.text(
            _("Complete FQDN VM name:"),
            qmark="",
            default=vm_name
        ).ask()
        fqdn = is_fqdn(vm_name)
    return vm_name


def get_vmIP():
    vm_ip = ""
    ip = False
    while (not vm_ip or not ip):
        if (vm_ip.strip() != "" and not ip):
            Display.box(_("Please enter a correct IPv4. Example: 172.16.0.24"))
        vm_ip = questionary.text(
            _("IP Address:"),
            qmark="",
            default=vm_ip
        ).ask()
        ip = is_ipv4(vm_ip)

    # On ajoute un /32
    return f"{vm_ip}/32"


def get_vmIface():
    vm_iface = ""
    while (not vm_iface):
        vm_iface = questionary.text(
            _("Interface name:"),
            qmark="",
            default="eth0"
        ).ask()
    return vm_iface

def get_vmCluster():
    if (netbox):
        clusters = list(netbox.virtualization.clusters.all())
        if not clusters:
            RaiseError("No cluster was found in NetBox.")
        else:
            choice = questionary.select(
                _("Hypervisor related to this VM:"), 
                choices=[
                    questionary.Choice(c.name, c.id) for c in clusters
                ],
                qmark="",
                pointer="󰜴",
                instruction=" "
            ).ask()
    
    return netbox.virtualization.clusters.get(choice)

def get_vmPlatform():
    if (netbox):
        platforms = list(netbox.dcim.platforms.all())
        if not platforms:
            RaiseError("No OS was found in NetBox.")
        else:
            choice = questionary.select(
                _("Select an OS:"), 
                choices=[
                    questionary.Choice(c.name, c.id) for c in platforms
                ],
                qmark="",
                pointer="󰜴",
                instruction=" "
            ).ask()
    
    return netbox.dcim.platforms.get(choice)

def get_role(role_name="serveur"):
    roles = list(netbox.dcim.device_roles.all())
    for role in roles:
        if role.name.lower() == role_name.lower():
            return role
    RaiseError("No role was found in NetBox.")

def get_tenant(cluster):
    if hasattr(cluster, "tenant") and cluster.tenant:
        tenant = netbox.tenancy.tenants.get(cluster.tenant.id)
        if tenant:
            return tenant
    return None

def _addOrUpdateVM(vmData):
    vms = list(netbox.virtualization.virtual_machines.filter(name=vmData['name']))

    if vms:
        vm = vms[0]
        if vm:
            vm.update(vmData)
            Display.label("Netbox", "VM updated")
            return vm
    
    vm = netbox.virtualization.virtual_machines.create(vmData)
    Display.label("Netbox", "VM created")
    return vm


def _addOrUpdateIFace(vm, vmIface):
    vmIface['virtual_machine'] = vm.id

    ifaces = list(netbox.virtualization.interfaces.filter(virtual_machine_id=vm.id, name=vmIface['name']))
    
    if ifaces:
        iface = ifaces[0]
        if iface:
            iface.update(vmIface)
            Display.label("Netbox", "Interface updated")
            return iface

    iface = netbox.virtualization.interfaces.create(vmIface)
    Display.label("Netbox", "Interface created")
    return iface


def _addOrUpdateIP(vm, iface, vmIPv4):
    vmIPv4['assigned_object_id'] = iface.id

    ips = list(netbox.ipam.ip_addresses.filter(address=vmIPv4['address']))
    
    if ips:
        ip = ips[0]
        print(ips)
        if ip:
            ip.update(vmIPv4)
            Display.label("Netbox", "IP address updated")
            return ip

    ip = netbox.ipam.ip_addresses.create(vmIPv4)
    Display.label("Netbox", "IP address created")

    vm.update({ "primary_ip4": ip.id })
    Display.label("Netbox", "Set IP address as default")

def addOrUpdateVM():
    clean_screen()

    Display.box(_("Add or update a VM"), Back.GREEN)

    cluster = get_vmCluster()

    vmData = {
        "role"     : get_role().id,
        "cluster"  : cluster.id,
        "name"     : get_vmName(),
        "platform" : get_vmPlatform().id,
        "tenant"   : get_tenant(cluster).id
    }

    vmIface = {
        "virtual_machine": 0,
        "type"     : "Virtual",
        "name"     : get_vmIface(),
    }

    vmIPv4 = {
        "address"   : get_vmIP(),
        "assigned_object_type": "virtualization.vminterface",
        "assigned_object_id": 0,
        "tenant"   : get_tenant(cluster).id
    }

    print()

    vm = _addOrUpdateVM(vmData)
    iface = _addOrUpdateIFace(vm, vmIface)
    _addOrUpdateIP(vm, iface, vmIPv4)

    print()



def navigation():
    Display.box('NAAC', Back.GREEN)

    while True:
        action = questionary.select(
            _("Select an action:"), 
            choices=[
                _("Add or update a VM"),
                _("Exit")
            ],
            qmark="",
            pointer="󰜴",
            instruction=" "
        ).ask()

        if action == _("Add or update a VM"):
            addOrUpdateVM()
        elif action == _("Exit"):
            clean_screen()
            quit()

def main():
    clean_screen()

    Configuration.load("/etc/NAAC/conf.yaml")

    setup_translation(Configuration.get("language","en"))

    netboxConnect()

    navigation()  

    print("\n\n")

if __name__ == "__main__":
    main()