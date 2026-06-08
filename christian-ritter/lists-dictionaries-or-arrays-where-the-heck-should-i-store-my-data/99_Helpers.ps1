function Get-ObjectId {
    param($obj)

    #region explanation
    # RuntimeHelpers.GetHashCode() returns an identity-based hash code
    # for the given object.
    #
    # IMPORTANT:
    # - This is NOT the memory address of the object
    # - It does NOT reflect the object's content (value)
    # - It is tied to the object *instance* (reference identity)
    #
    # Why this matters:
    # In .NET, objects can be moved in memory by the garbage collector,
    # so their physical address is not stable or normally exposed.
    #
    # This method gives us a stable identifier for the lifetime of the object,
    # allowing us to check whether two variables reference the *same instance*.
    #
    # Use case:
    # If this value changes after an operation (e.g. += on arrays),
    # it indicates that a NEW object was created.
    #endregion

    return [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($obj)
}

function prompt{
    'PSConfEU #WhereTheHeck > '
}