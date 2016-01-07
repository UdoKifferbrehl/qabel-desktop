package de.qabel.desktop.remoteFS;

import javafx.application.Application;

import javafx.application.Platform;
import javafx.event.EventHandler;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.shape.Path;
import javafx.stage.Stage;
import javafx.stage.StageStyle;
import javafx.stage.WindowEvent;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.net.URL;


public class RemoteFSApplication extends Application {

    private static final String TITLE = "Qabel Desktop Client";

    public static void main(String[] args) throws Exception {
        Application.launch(RemoteFSApplication.class, args);
    }

    @Override
    public void start(Stage primaryStage) throws Exception {

        primaryStage.setTitle(TITLE);

        if (SystemTray.isSupported()) {
            Platform.setImplicitExit(false);
            setTrayIcon(primaryStage);
        }


        Parent root = FXMLLoader.load(getClass().getResource("/fxml/RemoteFSView.fxml"));
        final Scene scene = new Scene(root, 600, 600);
        primaryStage.setScene(scene);
        primaryStage.show();
    }

    private void setTrayIcon(Stage primaryStage) {

        SystemTray sTray = SystemTray.getSystemTray();

        ActionListener listenerShow = new ActionListener() {

            @Override
            public void actionPerformed(ActionEvent e) {
                Platform.runLater(new Runnable() {

                    @Override
                    public void run() {
                        primaryStage.show();
                    }
                });
            }
        };

        ActionListener listenerClose = new ActionListener() {

            @Override
            public void actionPerformed(ActionEvent e) {
                System.exit(0);
            }
        };

        primaryStage.setOnCloseRequest(new EventHandler<WindowEvent>() {

            @Override
            public void handle(WindowEvent arg0) {
                primaryStage.hide();
            }
        });

        PopupMenu popup = new PopupMenu();
        MenuItem showItem = new MenuItem("Öffnen");
        MenuItem exitItem = new MenuItem("Beenden");

        showItem.addActionListener(listenerShow);
        exitItem.addActionListener(listenerClose);

        popup.add(showItem);
        popup.add(exitItem);

        URL url = System.class.getResource("/qabel-icon.png");
        Image img = Toolkit.getDefaultToolkit().getImage(url);
        TrayIcon icon = new TrayIcon(img, "Qabel", popup);
        icon.setImageAutoSize(true);

        try {
            sTray.add(icon);
        } catch (AWTException e) {
            System.err.println(e);
        }

    }
}

