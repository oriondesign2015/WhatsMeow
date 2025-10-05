// Exemplo de uso do WhatsMeow com a modificação de histórico desabilitado
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	_ "github.com/mattn/go-sqlite3"
	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/store"
	"go.mau.fi/whatsmeow/store/sqlstore"
	"go.mau.fi/whatsmeow/types/events"
	waLog "go.mau.fi/whatsmeow/util/log"
)

func main() {
	// =============================================================================
	// CONFIGURAÇÃO DE HISTÓRICO (OPCIONAL)
	// =============================================================================
	
	// Por padrão, o histórico JÁ está desabilitado (0 dias)!
	// Se você quiser PERSONALIZAR, descomente uma das linhas abaixo:
	
	// store.SetHistorySyncConfig(0, 0)   // Sem histórico (PADRÃO - já está assim)
	// store.SetHistorySyncConfig(0, 1)   // Apenas 1 dia de histórico recente
	// store.SetHistorySyncConfig(0, 7)   // Apenas 7 dias de histórico recente
	// store.SetHistorySyncConfig(30, 7)  // 30 dias completo + 7 dias recente
	
	// =============================================================================
	// SETUP DO BANCO DE DADOS
	// =============================================================================
	
	dbLog := waLog.Stdout("Database", "DEBUG", true)
	container, err := sqlstore.New("sqlite3", "file:whatsmeow.db?_foreign_keys=on", dbLog)
	if err != nil {
		panic(err)
	}
	defer container.Close()
	
	// Pegar o primeiro dispositivo ou criar um novo
	deviceStore, err := container.GetFirstDevice()
	if err != nil {
		panic(err)
	}
	
	// =============================================================================
	// CRIAR CLIENTE
	// =============================================================================
	
	clientLog := waLog.Stdout("Client", "INFO", true)
	client := whatsmeow.NewClient(deviceStore, clientLog)
	
	// =============================================================================
	// EVENT HANDLERS
	// =============================================================================
	
	client.AddEventHandler(func(evt interface{}) {
		switch v := evt.(type) {
		case *events.Message:
			// ✅ MENSAGENS NOVAS CHEGAM IMEDIATAMENTE!
			// Sem bloqueio por sincronização de histórico! 🎉
			
			msg := v.Message.GetConversation()
			if msg == "" {
				msg = v.Message.GetExtendedTextMessage().GetText()
			}
			
			fmt.Printf("\n📩 Nova mensagem de %s\n", v.Info.Sender)
			fmt.Printf("   Texto: %s\n", msg)
			fmt.Printf("   Hora: %s\n\n", v.Info.Timestamp)
			
		case *events.HistorySync:
			// Com o histórico desabilitado (0 dias), isso provavelmente nunca será chamado!
			// O WhatsApp simplesmente não envia histórico quando os limites são 0.
			fmt.Printf("⚠️  History sync recebido (raro com limites em 0): tipo=%s, progresso=%d%%\n",
				v.Data.GetSyncType(),
				v.Data.GetProgress())
			
		case *events.Connected:
			fmt.Println("\n✅ Conectado ao WhatsApp!")
			fmt.Println("📱 Mensagens novas chegarão instantaneamente!")
			fmt.Println("🚀 Sem bloqueio por sincronização de histórico!\n")
			
		case *events.StreamReplaced:
			fmt.Println("\n⚠️  Conexão substituída por outro dispositivo")
			os.Exit(0)
			
		case *events.Disconnected:
			fmt.Println("\n❌ Desconectado do WhatsApp")
		}
	})
	
	// =============================================================================
	// CONECTAR
	// =============================================================================
	
	if client.Store.ID == nil {
		// Dispositivo novo - precisa escanear QR code
		fmt.Println("📱 Novo dispositivo detectado!")
		fmt.Println("📷 Escaneie o QR code abaixo no WhatsApp:\n")
		
		qrChan, _ := client.GetQRChannel(context.Background())
		err = client.Connect()
		if err != nil {
			panic(err)
		}
		
		for evt := range qrChan {
			if evt.Event == "code" {
				fmt.Println("QR Code:", evt.Code)
				fmt.Println("\nOu acesse: https://api.qrserver.com/v1/create-qr-code/?size=256x256&data=" + evt.Code)
			} else {
				fmt.Println("Evento QR:", evt.Event)
			}
		}
	} else {
		// Dispositivo já registrado - apenas conectar
		fmt.Println("📱 Dispositivo já registrado, conectando...")
		err = client.Connect()
		if err != nil {
			panic(err)
		}
	}
	
	// =============================================================================
	// MANTER RODANDO
	// =============================================================================
	
	fmt.Println("\n✨ Aplicação rodando! Pressione Ctrl+C para sair.\n")
	
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	<-c
	
	fmt.Println("\n👋 Desconectando...")
	client.Disconnect()
	fmt.Println("✅ Encerrado com sucesso!")
}
