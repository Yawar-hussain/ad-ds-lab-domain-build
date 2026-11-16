# AD DS Lab: Domain Build & OU Design

> 🧪 **Home lab project.** This was built in my own test environment to practise and document Active Directory administration. It is not a production system.

## 1. Objective
Build a small company domain from scratch with a sensible OU structure, delegated helpdesk rights and baseline Group Policies, so new users and devices get the right settings automatically.

## 2. Environment
| Item | Detail |
|------|--------|
| Hypervisor | Hyper-V / VirtualBox (*edit to the one you use*) |
| Server | Windows Server 2025 Evaluation, VM name `DC01` |
| Domain | `yawarlab.local` |
| Roles | AD DS, DNS |
| Tooling | PowerShell 5.1, RSAT, Group Policy Management Console |
| Client (optional) | Windows 11 VM `CL01` joined to the domain |

## 3. Build steps
1. **Build the DC01 VM** (2 vCPU, 4 GB RAM, 60 GB disk). Set a static IP and point DNS to itself.
   ![Static IP](screenshots/01-static-ip.png)
2. **Install AD DS and promote DC01** to a new forest, `yawarlab.local`.
   ![Promote DC](screenshots/02-promote-dc.png)
3. **Create the OU structure** with [`scripts/New-LabOUs.ps1`](scripts/New-LabOUs.ps1).
   ![OU structure](screenshots/03-ou-structure.png)
4. **Delegate control.** The `Helpdesk` group can reset passwords and unlock accounts in the department OUs only.
5. **Create three GPOs:**
   - *Password policy* (Default Domain Policy or a fine-grained policy)
   - *Mapped drives* (linked to department OUs, item-level targeting by group)
   - *USB storage restriction* (linked to the Workstations OU)
6. **Verify:** `gpresult /r` and `gpupdate /force` on the client, plus DNS checks with `dcdiag /test:dns` and `nslookup`.
   ![gpresult](screenshots/06-gpresult.png)

## 4. Scripts
| Script | Purpose |
|--------|---------|
| [`New-LabOUs.ps1`](scripts/New-LabOUs.ps1) | Creates the company OU tree, department OUs and security groups |

## 5. What broke and how I fixed it
> Fill this in from `docs/troubleshooting-log.md`. **This is the most valuable section.**

| Symptom | Diagnosis | Fix |
|---------|-----------|-----|
| *e.g. Mapped drive GPO not applying* | *`gpresult /r` showed the GPO filtered out: security filtering didn't include Authenticated Users read* | *Added Authenticated Users with Read, kept the group with Apply* |
| | | |

## 6. What I would do differently in production
- Use at least **two domain controllers** for redundancy, and back up the system state.
- Use a **tiered admin model** with separate admin accounts, never daily accounts with admin rights.
- Use a **registered domain sub-zone** (e.g. `ad.company.com`) instead of `.local`.
