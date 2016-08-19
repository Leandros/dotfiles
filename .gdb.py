import sys

class IgnoreErrorsCommand (gdb.Command):
    def __init__ (self):
        super (IgnoreErrorsCommand, self).__init__ ("ignore-errors",
                                                    gdb.COMMAND_OBSCURE,
                                                    # FIXME...
                                                    gdb.COMPLETE_COMMAND)

    def invoke (self, arg, from_tty):
        try:
            gdb.execute (arg, from_tty)
        except:
            sys.stdout.write('<err> ')
            sys.stdout.flush()
            pass

IgnoreErrorsCommand ()

class IsValid (gdb.Function):
    def __init__ (self):
        super (IsValid, self).__init__("isvalid")

    def invoke (self, var):
        if var.__str__() == "<unavailable>":
            return 0
        else:
            return 1

IsValid ()
