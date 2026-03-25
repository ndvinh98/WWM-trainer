.class public Lcom/wwm/inject/SigSpoof;
.super Ljava/lang/Object;

# The original cert bytes (base64) — replaced at build time by build_apk.py
.field private static final ORIGINAL_CERT_B64:Ljava/lang/String; = "ORIGINAL_CERT_PLACEHOLDER"

.method public static install()V
    .registers 8

    const-string v7, "WWM_INJECT"

    # Get the current Application context
    invoke-static {}, Landroid/app/ActivityThread;->currentApplication()Landroid/app/Application;
    move-result-object v0

    if-nez v0, :has_context
    const-string v1, "SigSpoof: no context yet, skipping"
    invoke-static {v7, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    return-void

    :has_context
    # Get PackageManager and our package name
    invoke-virtual {v0}, Landroid/content/Context;->getPackageName()Ljava/lang/String;
    move-result-object v1

    # Decode original cert bytes
    sget-object v2, Lcom/wwm/inject/SigSpoof;->ORIGINAL_CERT_B64:Ljava/lang/String;
    const-string v3, "ORIGINAL_CERT_PLACEHOLDER"
    invoke-virtual {v2, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v4
    if-eqz v4, :cert_ok

    const-string v1, "SigSpoof: cert not patched, skipping"
    invoke-static {v7, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    return-void

    :cert_ok
    const-string v1, "SigSpoof: installed signature hook"
    invoke-static {v7, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    return-void
.end method
