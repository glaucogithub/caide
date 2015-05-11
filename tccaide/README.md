tccaide is a plugin for Topcoder arena required to support Topcoder problems
in caide tools.

# Installation

0. JRE 1.7+ is required.

1. Create a caide project in one of caide tools. See
   [libcaide](https://github.com/slycelote/caide/libcaide) for a command line
tool or [VsCaide](https://github.com/slycelote/caide/vscaide) for a Visual
Studio Extension.

2. Download tccaide.jar file from releases page.

3. Log into Arena and select Options -> Editor from main menu.

4. Click Add button. Use the following settings:
  * Name - caide
  * EntryPoint - net.slycelote.caide.EntryPoint
  * ClassPath - path to the jar file you downloaded.

5. Click OK, and then Configure.

6. Input path to caide project that you created in the first step. Click
   'Verify & Save'.

# Quick start

Simply open a problem in Topcoder Arena. Solution template and testing code
will be created automatically.

# Configuration

The topcoder plugin doesn't have any options. Refer to [libcaide
documentation](https://github.com/slycelote/caide/libcaide) for general caide
configuration.
