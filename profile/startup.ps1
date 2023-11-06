# function startup(){

# $title = "Launch Work Apps?"

# $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
#     "Deletes all the files in the folder."

# $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
#     "Retains all the files in the folder."

# $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

# $result = $host.ui.PromptForChoice($title, "", $options, 0) 

# $result2 = $host.ui.PromptForChoice("Launch Social", "", $options, 0) 
# $result3 = $host.ui.PromptForChoice("Launch Utility", "", $options, 0) 


# if ($result -eq 0){
#   &  "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\outlook 2016.lnk"
# }
# $result
# $result2
# $result3
# }
