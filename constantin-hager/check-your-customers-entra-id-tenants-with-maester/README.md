# Check Your Customers’ Entra ID Tenants with Maester

## Abstract

As a Managed Service Provider, whether we're designing a new Entra ID tenant or taking over an existing one, we’re often faced with the same challenge: understanding what’s already in place and where to begin. By the end of the project, we need a clear picture of the tenant’s security posture and a roadmap for what to tackle next. Continuous reporting is also essential, so the customer always knows the current state of their environment.

Maester a PowerShell-based security test automation framework built on Pester ships with ready-to-use tests and generates rich, visual reports that make it easy to spot misconfigurations. It integrates seamlessly with GitHub Actions, Azure DevOps, and Azure Automation, enabling us to run it across environments and deliver actionable insights to our customers.

In this session, I’ll walk you through how we deploy Maester in an Entra ID tenant, run it via GitHub Actions, and extend it with a self written custom test. If you’re managing multiple environments or looking to automate tenant security checks, this talk will give you practical tools and workflows you can adopt immediately.

## Code for the presenation
[Session](https://github.com/constantinhager/psconfeu2026-Maester)