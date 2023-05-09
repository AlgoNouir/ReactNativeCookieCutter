# --------------------------------+
#           preinstalling         |
# --------------------------------+

# loger function clear all outputs and echo steps
logs=()
function echoLog {
    clear
    logs+=("$1")
    for logStr in "${!logs[@]}"; do
        echo "${logs[logStr]} ($((logStr + 1))/5)"
    done
    return
}

# get app name and set it to defualt
read -r -p "app name:(app) " appName
if [[ -z "${appName}" ]]; then
    appName="app"
fi

# --------------------------------+
#         install expo app        |
# --------------------------------+

# install blank typescript expo app
npx create-expo-app "$appName" --template expo-template-blank-typescript
cd "$appName" || exit

echoLog "✅ $appName install done"
# --------------------------------+
#         create home page        |
# --------------------------------+

# create page folder
mkdir pages

# create home file
cat > "./pages/home.tsx" <<- EOM
// base
import * as React from "react";

// types
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { pagesType } from "./config";

// components
import { View, Text } from "react-native";

export default function Home(props: NativeStackScreenProps<pagesType, "home">) {
    return (
        <View className="w-screen h-screen items-center justify-center">
            <Text>your app is ready !!!</Text>
        </View>
    );
}
EOM

cat > "./pages/config.ts" <<- EOM
export type pagesType = {
    home: undefined;
};
EOM

cat > "./pages/index.tsx" <<- EOM
// base
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { pagesType } from "./config";


// pages
import HomePage from "./home";

const { Navigator, Screen, Group } = createNativeStackNavigator<pagesType>();

export default function Pages() {
    return (
        <Navigator>
          <Screen
            name="home"
            component={HomePage} 
          />
        </Navigator>
    );
}
EOM


mkdir components
cat > "./components/UI.ts" <<- EOM
import {
    Text,
    TextProps,
    TextInput,
    TextInputProps,
    TouchableOpacity,
    TouchableOpacityProps,
} from "react-native";

export function Button(props: TouchableOpacityProps) {
    return (
        <TouchableOpacity
            activeOpacity={0.6}
            className={props.className}
            {...props}
        />
    );
}

export function Label(props: TextProps) {
    return (
        <Text className={props.className + " font-main"} {...props}>
            {props.children}
        </Text>
    );
}
export function Input(props: TextInputProps) {
    return (
        <TextInput
            {...props}
            className={props.className + " rounded-xl bg-bg-200 p-2 font-main"}
        >
            {props.children}
        </TextInput>
    );
}
EOM

# --------------------------------+
#   install and config tailwind   |
# --------------------------------+

echo "installing nativewind ..."

# install tailwind
npm install nativewind
npm install --dev tailwindcss
npm install --dev prettier prettier-plugin-tailwindcss
npx tailwindcss init


# config tailwind
cat > "./tailwind.config.js" <<- EOM
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './App.{js,jsx,ts,tsx}', 
    './pages/**/*.{js,jsx,ts,tsx}', 
    './components/**/*.{js,jsx,ts,tsx}'
  ],
  theme: {
    fontFamily: {
        main: "Vazirmatn_500Medium",
    },
    colors: {
        prime:{100:"#EDEDED", 200:"#EDEDED", 300:"#EDEDED"},
        bg:{100:"#EDEDED", 200:"#EDEDED", 300:"#EDEDED"},
        accent:{100:"#EDEDED", 200:"#EDEDED",},
        text:{100:"#EDEDED", 200:"#EDEDED",},
        
        error: "#C4716C",
        success: "#1DC322",
        info: "#3A5290",
        warning:"#E7B10A",
    
        white: "#FFF",
        black: "#000",
        red: "#C4716C",
        green: "#1DC322",
        blue: "#3A5290",
    },
  },
  plugins: [],
}
EOM
sed -i '' "s#return {#return {plugins: ['nativewind/babel'],#" "babel.config.js"

# create core folder for export tailwind
mkdir core
cat > "./core/index.ts" <<- EOM
export const colors = require("../tailwind.config").theme.colors
EOM

# set className to components
echo "/// <reference types='nativewind/types' />" > app.d.ts

echoLog "✅ nativewind install done"

# --------------------------------+
#    install navigation and set   |
# --------------------------------+

echo "installing redux ..."

# install dependencies
npm install @reduxjs/toolkit react-redux

# create file
mkdir store
cd store || exit
cat > "./store.ts" <<- EOM
import { Action, configureStore, ThunkAction } from "@reduxjs/toolkit";
import user from "./user/slice"

export const store = configureStore({
    reducer: {
      user
    },
});

export type AppDispatch = typeof store.dispatch;
export type RootState = ReturnType<typeof store.getState>;
export type AppThunk<ReturnType = void> = ThunkAction<
    ReturnType,
    RootState,
    unknown,
    Action<string>
>;
EOM

cat > "./HOCs.ts" <<- EOM
import { TypedUseSelectorHook, useDispatch, useSelector } from "react-redux";
import type { AppDispatch, RootState } from "./store";

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
EOM


mkdir user
cat > "./user/slice.ts" <<- EOM
import { createSlice } from "@reduxjs/toolkit";

export interface UserType {
    name: string;
}
const initialState: {
    login: "accepted" | "rejected" | "pending" | "onLogin";
    account: UserType;
} = {
    login: "accepted",
    account: {
        name: "مهدی نوری",
    },
};

const userSlice = createSlice({
    name: "userSlice",
    initialState,
    reducers: {},
});

export default userSlice.reducer;
EOM

cd ..

echoLog "✅ redux install done"

# --------------------------------+
#    install navigation and set   |
# --------------------------------+

echo "installing the navigations ..."
npm install @react-navigation/native @react-navigation/native-stack
npx expo install react-native-screens react-native-safe-area-context
npx expo install @expo-google-fonts/vazirmatn expo-splash-screen expo-font
# set app navigations to home page
cat > "./App.tsx" <<- EOM
// base
import { NavigationContainer } from "@react-navigation/native";
import { Provider } from "react-redux";
import { store } from "./store/store";
import { Vazirmatn_500Medium } from "@expo-google-fonts/vazirmatn";
import { useCallback, useEffect, useState } from "react";
import * as SplashScreen from "expo-splash-screen";
import * as Font from "expo-font";
import Pages from "./pages";

export default function App() {
    const [appIsReady, setAppIsReady] = useState(false);

    useEffect(() => {
        async function prepare() {
            try {
                await Font.loadAsync({
                    Vazirmatn_500Medium,
                });
            } catch (e) {
                console.warn(e);
            } finally {
                // Tell the application to render
                setAppIsReady(true);
            }
        }

        prepare();
    }, []);
    const onLayoutRootView = useCallback(async () => {
        if (appIsReady) {
            await SplashScreen.hideAsync();
        }
    }, [appIsReady]);

    if (!appIsReady) {
        return null;
    }
    return (
        <Provider store={store}>
            <NavigationContainer onReady={onLayoutRootView}>
                <Pages />
            </NavigationContainer>
        </Provider>
    );
}

EOM

echoLog "✅ navigation install done"

# --------------------------------+
#        git init and commit      |
# --------------------------------+
echo "initial git and commit ..."

git init
git add -A
git commit -m "install the project via cookie"

echoLog "✅ git commited"

echo "happy hacking!!! 👑"