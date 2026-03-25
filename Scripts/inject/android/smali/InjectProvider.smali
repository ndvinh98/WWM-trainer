.class public Lcom/wwm/inject/InjectProvider;
.super Landroid/content/ContentProvider;

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/content/ContentProvider;-><init>()V
    return-void
.end method

.method public onCreate()Z
    .registers 3

    # Load our native hook library
    const-string v0, "inject"

    :try_start
    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V
    :try_end
    .catch Ljava/lang/UnsatisfiedLinkError; {:try_start .. :try_end} :catch_load

    # Install signature spoofing
    :try_start_spoof
    invoke-static {}, Lcom/wwm/inject/SigSpoof;->install()V
    :try_end_spoof
    .catch Ljava/lang/Exception; {:try_start_spoof .. :try_end_spoof} :catch_spoof

    const/4 v0, 0x1
    return v0

    :catch_load
    move-exception v1
    # Log but don't crash — game should still work
    const-string v0, "WWM_INJECT"
    invoke-virtual {v1}, Ljava/lang/UnsatisfiedLinkError;->getMessage()Ljava/lang/String;
    move-result-object v1
    invoke-static {v0, v1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I
    const/4 v0, 0x1
    return v0

    :catch_spoof
    move-exception v1
    const-string v0, "WWM_INJECT"
    invoke-virtual {v1}, Ljava/lang/Exception;->getMessage()Ljava/lang/String;
    move-result-object v1
    invoke-static {v0, v1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I
    const/4 v0, 0x1
    return v0
.end method

# Required ContentProvider stubs (all return null/0)

.method public query(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
    .registers 7
    const/4 v0, 0x0
    return-object v0
.end method

.method public getType(Landroid/net/Uri;)Ljava/lang/String;
    .registers 3
    const/4 v0, 0x0
    return-object v0
.end method

.method public insert(Landroid/net/Uri;Landroid/content/ContentValues;)Landroid/net/Uri;
    .registers 4
    const/4 v0, 0x0
    return-object v0
.end method

.method public delete(Landroid/net/Uri;Ljava/lang/String;[Ljava/lang/String;)I
    .registers 5
    const/4 v0, 0x0
    return v0
.end method

.method public update(Landroid/net/Uri;Landroid/content/ContentValues;Ljava/lang/String;[Ljava/lang/String;)I
    .registers 6
    const/4 v0, 0x0
    return v0
.end method
