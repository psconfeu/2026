# Generate a new Stepper script
New-StepperScript -Name Show-StepperTemplate

# Generate a new Stepper script that showcases Stepper functionality
New-StepperScript -Name Show-StepperShowcase -Showcase

# Test scripts
Test-StepperScript -Path ./Show-StepperShowcase.ps1

# Repair scripts
Repair-StepperScript -Path ./Show-StepperShowcase.ps1

# Convert new variables
ConvertTo-StepperScript -Path ./Show-StepperShowcase.ps1